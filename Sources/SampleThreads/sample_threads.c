//
//  sample_threads.c
//  TestAppPower
//
//  Created by Raúl Montón Pinillos on 14/1/24.
//

#include "sample_threads.h"
#include "get_backtrace.h"
#include "get_cpu_usage.h"
#include <dispatch/dispatch.h>
#include <stdlib.h>
#include <mach/mach_init.h>
#include <mach/mach_port.h>
#include <mach/task_info.h>
#include <mach/thread_act.h>
#include <mach/vm_map.h>
#include <mach/task.h>
#include <mach/mach_time.h>
#include <stdio.h>

// Technically private structs, from:
// https://github.com/apple-oss-distributions/xnu/blob/aca3beaa3dfbd42498b42c5e5ce20a938e6554e5/bsd/sys/proc_info.h#L153
struct proc_threadcounts_data {
    uint64_t ptcd_instructions;
    uint64_t ptcd_cycles;
    uint64_t ptcd_user_time_mach;
    uint64_t ptcd_system_time_mach;
    uint64_t ptcd_energy_nj;
};

struct proc_threadcounts {
    uint16_t ptc_len;
    uint16_t ptc_reserved0;
    uint32_t ptc_reserved1;
    struct proc_threadcounts_data ptc_counts[20];
};

// PROC_PIDTHREADCOUNTS is also private, see:
// https://github.com/apple-oss-distributions/xnu/blob/aca3beaa3dfbd42498b42c5e5ce20a938e6554e5/bsd/sys/proc_info.h#L927
#define PROC_PIDTHREADCOUNTS 34

// On macOS, proc_pidinfo is available as part of the libproc headers. On iOS, those
// headers are not available.
int proc_pidinfo(int pid, int flavor, uint64_t arg, void *buffer, int buffersize);

// Convert mach_time (monotonous clock ticks) to seconds.
static double convert_mach_time(uint64_t mach_time) {
    static mach_timebase_info_data_t base = { .numer = 0 };
    if (base.numer == 0) {
        mach_timebase_info(&base);
    }
    double elapsed = (mach_time * base.numer) / base.denom;
    return elapsed / 1e9;
}

sample_threads_result sample_threads(int pid, bool retrieve_dispatch_queue_names, bool retrieve_backtraces) {
 
    mach_port_t me = mach_task_self();
    kern_return_t res;
    thread_array_t threads;
    mach_msg_type_number_t n_threads;
    
    // Here we'd expect task_threads to always succeed as the process being inspected
    // is the same process that is making the call. Attempting to inspect tasks for
    // different processes raises KERN_FAILURE unless the caller has root privileges.
    //
    // task_threads(me, &threads, &n_threads) retrieves all the threads for the current
    // process.
    //
    // TODO/Note: I believe that with very few extra steps just before this code (using
    // proc_listpids to get the pids of all running processes on the system and using
    // task_for_pid to get the task from the pid), one could easily build macOS's
    // powermetrics utility.
    // Of course, the same limitations would apply (needing to run as root) as both
    // proc_listpids and task_for_pid return KERN_FAILURE if not running as root.
    res = task_threads(me, &threads, &n_threads);
    if (res != KERN_SUCCESS) {
        // TODO: Handle error...
    }
    
    sampled_thread_info_w_backtrace_t *counters_array = malloc(sizeof(sampled_thread_info_w_backtrace_t) * n_threads);
    
    // Loop over all the threads of the current process.
    for (int i = 0; i < n_threads; i++) {
        struct thread_identifier_info th_info;
        mach_msg_type_number_t th_info_count = THREAD_IDENTIFIER_INFO_COUNT;
        thread_t thread = threads[i];
        
        // We use thread_info to retrieve the Mach thread id of the thread we want to
        // retrieve power counters from.
        kern_return_t info_result = thread_info(thread,
                                                THREAD_IDENTIFIER_INFO,
                                                (thread_info_t)&th_info,
                                                &th_info_count);
        
        // As before, we expect thread_info to succeed as the thread being inspected
        // has the same parent process.
        if (info_result != KERN_SUCCESS) {
            // TODO: Handle error...
        }
        
        counters_array[i].info.thread_id = th_info.thread_id;
        
        // Attempt to retrieve the thread name
        struct thread_extended_info th_extended_info;
        mach_msg_type_number_t th_extended_info_count = THREAD_EXTENDED_INFO_COUNT;
        kern_return_t extended_info_result = thread_info(thread,
                                                         THREAD_EXTENDED_INFO,
                                                         (thread_info_t)&th_extended_info,
                                                         &th_extended_info_count);
        if (extended_info_result == KERN_SUCCESS) {
            strcpy(counters_array[i].info.pthread_name, th_extended_info.pth_name);
        } else {
            strcpy(counters_array[i].info.pthread_name, "");
        }
        
        // Attempt to retrieve the libdispatch queue
        if (retrieve_dispatch_queue_names) {
            struct thread_identifier_info th_id_info;
            mach_msg_type_number_t th_id_count = THREAD_IDENTIFIER_INFO_COUNT;
            kern_return_t id_info_result = thread_info(thread,
                                                       THREAD_IDENTIFIER_INFO,
                                                       (thread_info_t)&th_id_info,
                                                       &th_id_count);
            
            dispatch_queue_t * _Nullable thread_queue = th_id_info.dispatch_qaddr;
            if (id_info_result == KERN_SUCCESS && thread_queue != NULL) {
                // TODO: This crashes sometimes, need to investigate why
                const char  * _Nullable queue_label = dispatch_queue_get_label(*thread_queue);
                strcpy(counters_array[i].info.dispatch_queue_name, queue_label);
            } else {
                strcpy(counters_array[i].info.dispatch_queue_name, "");
            }
        }
        
        // Retrieve power counters info
        
        struct proc_threadcounts current_counters;
        
        // This flavor of proc_pidinfo using PROC_PIDTHREADCOUNTS is technically private, see:
        // https://github.com/apple-oss-distributions/xnu/blob/aca3beaa3dfbd42498b42c5e5ce20a938e6554e5/bsd/sys/proc_info.h#L898
        // Reproduced below in case link is not available in the future:
        //
        // PROC_PIDTHREADCOUNTS returns a list of counters for the given thread,
        // separated out by the "perf-level" it was running on (typically either
        // "performance" or "efficiency").
        //
        // This interface works a bit differently from the other proc_info(3) flavors.
        // It copies out a structure with a variable-length array at the end of it.
        // The start of the `proc_threadcounts` structure contains a header indicating
        // the length of the subsequent array of `proc_threadcounts_data` elements.
        //
        // To use this interface, first read the `hw.nperflevels` sysctl to find out how
        // large to make the allocation that receives the counter data:
        //
        //     sizeof(proc_threadcounts) + nperflevels * sizeof(proc_threadcounts_data)
        //
        // Use the `hw.perflevel[0-9].name` sysctl to find out which perf-level maps to
        // each entry in the array.
        //
        // The complete usage would be (omitting error reporting):
        //
        //     uint32_t len = 0;
        //     int ret = sysctlbyname("hw.nperflevels", &len, &len_sz, NULL, 0);
        //     size_t size = sizeof(struct proc_threadcounts) +
        //             len * sizeof(struct proc_threadcounts_data);
        //     struct proc_threadcounts *counts = malloc(size);
        //     // Fill this in with a thread ID, like from `PROC_PIDLISTTHREADS`.
        //     uint64_t tid = 0;
        //     int size_copied = proc_info(getpid(), PROC_PIDTHREADCOUNTS, tid, counts,
        //             size);
        proc_pidinfo(pid, // pid of the process
                     PROC_PIDTHREADCOUNTS, // The proc_pidinfo "flavor": different flavors have different return structures.
                     th_info.thread_id, // The mach thread id of the thread we're retrieving the counters from.
                     &current_counters, // The address of the result structure.
                     sizeof(struct proc_threadcounts)); // The size of the result structure.
        
        // Thread counters when running on Performance cores
        uint64_t p_cycles = current_counters.ptc_counts[0].ptcd_cycles;
        double p_energy = current_counters.ptc_counts[0].ptcd_energy_nj / 1e9;
        double p_time = convert_mach_time(current_counters.ptc_counts[0].ptcd_user_time_mach + current_counters.ptc_counts[0].ptcd_system_time_mach);
        
        // Thread counters when running on Efficiency cores
        uint64_t e_cycles = current_counters.ptc_counts[1].ptcd_cycles;
        double e_energy = current_counters.ptc_counts[1].ptcd_energy_nj / 1e9;
        double e_time = convert_mach_time(current_counters.ptc_counts[1].ptcd_user_time_mach + current_counters.ptc_counts[1].ptcd_system_time_mach);
        
        counters_array[i].info.performance.cycles = p_cycles;
        counters_array[i].info.performance.energy = p_energy;
        counters_array[i].info.performance.time = p_time;
        
        counters_array[i].info.efficiency.cycles = e_cycles;
        counters_array[i].info.efficiency.energy = e_energy;
        counters_array[i].info.efficiency.time = e_time;
        
        // Backtrace
        if (retrieve_backtraces) {
            counters_array[i].backtrace = get_backtrace(thread);
        }
        
        // Usage
        get_cpu_usage();
    }
    
    sample_threads_result result;
    result.thread_count = n_threads;
    result.cpu_counters = counters_array;
    return result;
}
