//
//  get_cpu_usage.c
//  
//
//  Created by Raúl Montón Pinillos on 21/4/24.
//

#include "get_cpu_usage.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#include <mach/mach.h>
#include <mach/processor_info.h>
#include <mach/mach_host.h>

cpu_usage_t get_cpu_usage() {
    processor_info_array_t cpu_info;
    mach_msg_type_number_t num_CPUs_info;
    int num_CPUs;
    kern_return_t err = host_processor_info(mach_host_self(),
                                            PROCESSOR_CPU_LOAD_INFO,
                                            &num_CPUs,
                                            &cpu_info,
                                            &num_CPUs_info);
    
    cpu_usage_t cpu_usage;
    cpu_usage.num_cores = num_CPUs;
    cpu_usage.core_usages = malloc(num_CPUs * sizeof(core_usage_t));
    
    for(int i = 0; i < num_CPUs; ++i) {
        core_usage_t core_usage;
        
        // Here CPU_STATE_MAX is the number of possible CPU states
        core_usage.system_ticks = cpu_info[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM];
        core_usage.user_ticks = cpu_info[(CPU_STATE_MAX * i) + CPU_STATE_USER];
        core_usage.nice_ticks = cpu_info[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
        core_usage.idle_ticks = cpu_info[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
                
        cpu_usage.core_usages[i] = core_usage;
    }
    
    return cpu_usage;
}
