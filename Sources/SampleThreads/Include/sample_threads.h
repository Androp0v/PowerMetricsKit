//
//  sample_threads.h
//  TestAppPower
//
//  Created by Raúl Montón Pinillos on 14/1/24.
//

#ifndef sample_threads_h
#define sample_threads_h

#include <stdint.h>
#include <stdbool.h>
#include "get_backtrace.h"

typedef struct {
    /// Cycles executed by the thread.
    uint64_t cycles;
    /// Energy used by thread, J.
    double energy;
    /// Sampling interval in seconds.
    double time;
} cpu_counters_t;

typedef struct {
    /// Thread ID.
    uint64_t thread_id;
    /// Name of the pthread, if any
    char pthread_name[64];
    /// Name of the thread's Dispatch Queue, if any
    char dispatch_queue_name[128];
    /// Performance core counters.
    cpu_counters_t performance;
    /// Efficiency core counters.
    cpu_counters_t efficiency;
} sampled_thread_info_t;

typedef struct {
    /// The energy sampling info.
    sampled_thread_info_t info;
    /// The backtrace, if any.
    backtrace_t backtrace;
} sampled_thread_info_w_backtrace_t;

typedef struct {
    uint64_t thread_count;
    sampled_thread_info_w_backtrace_t *cpu_counters;
} sample_threads_result;

sample_threads_result sample_threads(int pid);

#endif /* sample_threads_h */
