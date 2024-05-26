//
//  get_backtrace.c
//  
//
//  Created by Raúl Montón Pinillos on 4/3/24.
//

#include "get_backtrace.h"

#if defined(__aarch64__)
#include <stdlib.h>
#include <stdio.h>
#include <execinfo.h>
#include <signal.h>
#include <pthread.h>
#include <mach/mach_init.h>
#include <mach/thread_act.h>
#include <mach/vm_map.h>
#include <mach-o/loader.h>
#include <dlfcn.h>
#include <mach-o/dyld_images.h>

#import <mach-o/dyld.h>

static void print_backtrace(int line, uint64_t address, intptr_t aslr_slide) {
    Dl_info info;
    if (dladdr((const void *) address, &info) != 0) {
        const char *p = strrchr(info.dli_fname, '/');
        printf("%d %s %p\n",
               line,
               p + 1,
               (void *)(address - aslr_slide));
    } else if (address == 0x0) {
        printf("%d Unable to retrieve caller address. \n", line);
    } else {
        // Address doesn't point into a Mach-O memory section.
        printf("%d Unable to retrieve Mach-O image from address. \n", line);
    }
}

static backtrace_t build_backtrace(uint64_t *addresses, int length, intptr_t aslr_slide) {
    
    backtrace_t backtrace;
    backtrace.addresses = malloc(length * sizeof(backtrace_address_t));
    backtrace.length = length;
    
    Dl_info info;
    for (int i = 0; i < length; i++) {
        backtrace_address_t address;
        address.address = addresses[i];
        backtrace.addresses[i] = address;
    }
        
    return backtrace;
}

static backtrace_t backtracer(intptr_t aslr_slide) {
    
    void *array[MAX_FRAME_DEPTH];
    int size;
    size = backtrace(array, MAX_FRAME_DEPTH);
    
    #if defined(PRINT_BACKTRACES)
    printf("[Thread]\n");
    for (int i = 0; i < size; i++) {
        print_backtrace(i, array[i], aslr_slide);
    }
    printf("\n");
    #endif
    
    return build_backtrace((uint64_t *) array, size, aslr_slide);
}

intptr_t get_aslr_slide() {
    uint32_t numImages = _dyld_image_count();
    for (uint32_t i = 0; i < numImages; i++) {
        const struct mach_header *header = _dyld_get_image_header(i);
        const char *name = _dyld_get_image_name(i);
        const char *p = strrchr(name, '/');
    }
    
    struct task_dyld_info dyld_info;
    mach_vm_address_t image_infos;
    struct dyld_all_image_infos *infos;
    
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    kern_return_t ret;
    
    ret = task_info(mach_task_self_,
                    TASK_DYLD_INFO,
                    (task_info_t)&dyld_info,
                    &count);
    
    if (ret != KERN_SUCCESS) {
        return (intptr_t) NULL;
    }
    
    image_infos = dyld_info.all_image_info_addr;
    
    infos = (struct dyld_all_image_infos *)image_infos;
    return (intptr_t) infos->dyldImageLoadAddress;
}

bool apply_offset(mach_vm_address_t base_address, int64_t offset, mach_vm_address_t *result) {
    /* Check for overflow */
    if (offset > 0 && UINT64_MAX - offset < base_address) {
        return false;
    } else if (offset < 0 && (offset * -1) > base_address) {
        return false;
    }
    
    if (result != NULL) {
        *result = base_address + offset;
    }
    
    return true;
}

kern_return_t task_memcpy(mach_port_t task, mach_vm_address_t address, int64_t offset, void *dest, mach_vm_size_t length) {
    mach_vm_address_t target;
    kern_return_t kt;

    /* Compute the target address and check for overflow */
    if (!apply_offset(address, offset, &target)) {
        // TODO: Handle error...
    }
    
    vm_size_t read_size = length;
    return vm_read_overwrite(task, target, length, (pointer_t) dest, &read_size);
}

backtrace_t frame_walk(mach_port_t task, arm_thread_state64_t thread_state, vm_address_t aslr_slide) {
    int depth = 0;
    uint64_t frame_pointer_addresses[MAX_FRAME_DEPTH] = { 0 };
    uint64_t caller_addresses[MAX_FRAME_DEPTH] = { 0 };
    
    uint64_t current_frame_pointer;
    uint64_t next_frame_pointer;
    
    Dl_info info;
    #if defined(PRINT_BACKTRACES)
    printf("[Thread]\n");
    #endif
    if (dladdr((const void *) thread_state.__lr, &info) != 0) {
        // Let's walk the stack only for known images...
        while (true) {
            
            if (depth == 0) {
                uint64_t initial_frame_pointer = (thread_state.__fp & PAC_STRIPPING_BITMASK);
                current_frame_pointer = (initial_frame_pointer & PAC_STRIPPING_BITMASK);
            }
            
            if (current_frame_pointer == 0x0) {
                // TODO: Terminated frame
                break;
            }
            
            kern_return_t result = task_memcpy(task,
                                               current_frame_pointer,
                                               0,
                                               &next_frame_pointer,
                                               sizeof(int64_t));
            if (result != KERN_SUCCESS) {
                break;
            }
            next_frame_pointer = (next_frame_pointer & PAC_STRIPPING_BITMASK);
            
            // Get the caller address (Link Register, lr) knowing it's a 8-byte offset from the
            // frame pointer (fp).
            uint64_t caller_address;
            uint64_t caller_address_pointer = (current_frame_pointer & PAC_STRIPPING_BITMASK) + 8;
            kern_return_t caller_retrieval_result = task_memcpy(task,
                                                                caller_address_pointer,
                                                                0,
                                                                &caller_address,
                                                                sizeof(void *));
            // TODO:
            // Investigate why this doesn't always match the lr register of the thread_state
            // at depth 0, accessed via thread_state.__lr.
            caller_address = caller_address & PAC_STRIPPING_BITMASK;
            
            // Save info for this frame
            frame_pointer_addresses[depth] = current_frame_pointer;
            if (caller_retrieval_result == KERN_SUCCESS) {
                caller_addresses[depth] = caller_address;
            }
            
            // Update depth and exit if max depth reached
            depth += 1;
            if (depth >= MAX_FRAME_DEPTH) {
                break;
            }
            current_frame_pointer = next_frame_pointer;
        }
        
        int valid_address_length = 0;
        for (int i = 0; i < MAX_FRAME_DEPTH; i++) {
            if (frame_pointer_addresses[i] == 0x0) {
                break;
            }
            valid_address_length += 1;
            #if defined(PRINT_BACKTRACES)
            print_backtrace(i, caller_addresses[i], aslr_slide);
            #endif
        }
        #if defined(PRINT_BACKTRACES)
        printf("\n");
        #endif
        return build_backtrace(caller_addresses, valid_address_length, aslr_slide);
    } else {
        #if defined(PRINT_BACKTRACES)
        printf("Image unknown \n\n");
        #endif
        backtrace_t backtrace;
        backtrace.length = 0;
        return backtrace;
    }
}
#endif

backtrace_t get_backtrace(thread_t thread) {
    
    #if defined(__aarch64__)
    thread_t current_thread = mach_thread_self();
    vm_address_t aslr_slide = get_aslr_slide();
    
    if (current_thread == thread) {
        return backtracer(aslr_slide);
    } else {
        thread_suspend(thread);

        mach_msg_type_number_t state_count = ARM_THREAD_STATE64_COUNT;
        arm_thread_state64_t thread_state;
        kern_return_t thread_state_result = thread_get_state(thread,
                                                             ARM_THREAD_STATE64,
                                                             (thread_state_t) &thread_state,
                                                             &state_count);
        backtrace_t backtrace = frame_walk(mach_task_self(), thread_state, aslr_slide);
        
        thread_resume(thread);
        
        return backtrace;
    }
    #else
    backtrace_t backtrace;
    backtrace.length = 0;
    return backtrace;
    #endif
}
