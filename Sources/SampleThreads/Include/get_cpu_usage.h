//
//  get_cpu_usage_h.h
//
//
//  Created by Raúl Montón Pinillos on 21/4/24.
//

#ifndef get_cpu_usage_h
#define get_cpu_usage_h

#include <stdint.h>
#include <stdio.h>

typedef struct {
    /// Number of CPU ticks used at system-level.
    uint64_t system_ticks;
    /// Number of CPU ticks used at user-level with application priority.
    uint64_t user_ticks;
    /// Number of CPU ticks used at user-level with nice priority.
    uint64_t nice_ticks;
    /// Number of idle CPU ticks.
    uint64_t idle_ticks;
} core_usage_t;

typedef struct {
    /// Number of cores.
    int num_cores;
    /// The core usage of each core.
    core_usage_t *core_usages;
} cpu_usage_t;

cpu_usage_t get_cpu_usage();

#endif /* get_cpu_usage_h */
