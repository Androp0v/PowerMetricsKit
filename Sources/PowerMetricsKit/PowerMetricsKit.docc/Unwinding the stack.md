# Deep Dive: Unwinding the stack

Get to know how the code to obtain the backtraces for all the threads in the process works.

## Overview

This feature only works on AArch64, although it should be trivial to implement in other platforms. The steps to unwind the stack are described below, and explain the inner workings of `get_backtrace.c` in the associated `SampleThreads` library listed in ``PowerMetricsKit``'s dependencies.

### Retrieving the stack contents

To retrieve the content of a thread, we must first suspend it, which is done by calling Mach's `thread_suspend`. Then, the state of the thread is acquired using `thread_get_state`, which also retrieves the contents of the registers:
```c
thread_suspend(thread);
mach_msg_type_number_t state_count = ARM_THREAD_STATE64_COUNT;
arm_thread_state64_t thread_state;
kern_return_t thread_state_result = thread_get_state(
    thread,
    ARM_THREAD_STATE64,
    (thread_state_t) &thread_state,
    &state_count
);
```
Here, the call to `thread_get_state` places the fetched state of the thread into `thread_state`. `ARM_THREAD_STATE64` specifies the format of the thread state to fetch (in this case: the format for AArch64).

- WARNING: Suspending a thread before unwinding its stack is required to ensure the stack is not being modified at the same time we're reading its contents. Care should be taken when suspending threads. 
- WARNING: On macOS/iOS, `dladdr` uses mutexes internally, so it's possible to deadlock the sampling process by having `dladdr` wait on a lock that is currently held by one of the suspended threads.

Once the state of the target thread has been acquired, we now want to find the addresses of the symbols in the Mach-O binary file that make up the call stack. To do that, we start by reading the latest contents of `fp` (the Frame Pointer). The Procedure Call Standard for the Arm 64-bit Architecture says:
> Procedure Call Standard for the Arm 64-bit Architecture: Conforming code shall construct a linked list of stack-frames. Each frame shall link to the frame of its caller by means of a frame record of two 64-bit values on the stack (independent of the data model). The frame record for the innermost frame (belonging to the most recent routine invocation) shall be pointed to by the Frame Pointer register (FP). The lowest addressed double-word shall point to the previous frame record and the highest addressed double-word shall contain the value passed in LR on entry to the current function. If code uses the pointer signing extension to sign return addresses, the value in LR must be signed before storing it in the frame record. The end of the frame record chain is indicated by the address zero in the address for the previous frame. The location of the frame record within a stack frame is not specified.

Thus, if we have the address of the frame pointer of the Nth frame in the stack, the address of the previous frame pointer (the (N-1)th frame) is simply the address stored in the current (Nth) frame pointer. And, for any given frame pointer, the `lr` (the Link Register) is just the address of the frame pointer plus 64 bits (8 bytes):

![StackWalk](StackWalk)

When we first get the `thread_state` of a thread, we don't know where the frame pointer of the last frame is stored in memory. Thankfully, the `fp` register in AArch64 _usually_ holds the value of the frame pointer of the last frame (the compiler can optimize this out in some scenarios, but we're going to ignore those cases).

The C code that achieves this:

```c
kern_return_t result = task_memcpy(
    task,
    current_frame_pointer,
    0,
    &next_frame_pointer,
    sizeof(int64_t)
);
if (result != KERN_SUCCESS) {
    break;
}
next_frame_pointer = (next_frame_pointer & PAC_STRIPPING_BITMASK);

// Get the caller address (Link Register, lr) knowing it's a 8-byte 
// offset from the frame pointer (fp).
uint64_t caller_address;
uint64_t caller_address_pointer = 8 + (current_frame_pointer & PAC_STRIPPING_BITMASK);
kern_return_t caller_retrieval_result = task_memcpy(
    task,
    caller_address_pointer,
    0,
    &caller_address,
    sizeof(void *)
);
```
Which essentially allows us to walk back one step in the frame pointer linked list. Here `task_memcpy` wraps around `vm_read_overwrite` to safely attempt to copy the contents of a memory address (failing without crashing/signaling if the address is protected), and `PAC_STRIPPING_BITMASK` is a constant used to strip [Pointer Authentication Codes](https://developer.apple.com/documentation/security/preparing_your_app_to_work_with_pointer_authentication?) (PACs) from the memory addresses. 

The `caller_address` will be saved and passed back to the Swift side of the package, where `dladdr` will be used to obtain symbol information.

Once this step has been performed once, it's iteratively repeated until the frame pointer points to `0x0` (zero), meaning this is the first frame in the stack, or until the max backtrace length (`MAX_BACKTRACE_LENGTH`) is reached.

### Retrieving symbol information

The caller addresses are then sent back to Swift, and the ``SymbolicateBacktraces`` class uses `dladdr` to obtain symbol information about them. Crucially, all the images loaded by dyld are loaded at a random offset (called the ASLR slide), so the memory address of the loaded symbols is different on each app launch. The base address of the image of a specific address is retrieved as part of `dladdr`'s `Dl_Info` object, which contains a `dli_fbase` property with the base address of the image. Subtracting the base image address from an address obtained in a backtrace results in the address of the symbol in the Mach-O file.

For more information on the how dyld loads the images and why the ASLR slide is needed, see [Symbolication: Beyond the basics](https://developer.apple.com/wwdc21/10211).
