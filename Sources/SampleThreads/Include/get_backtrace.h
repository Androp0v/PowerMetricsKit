//
//  get_backtrace.h
//  
//
//  Created by Raúl Montón Pinillos on 4/3/24.
//

#ifndef get_backtrace_h
#define get_backtrace_h

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <mach/mach_types.h>

// Max number of frames in stack trace
#define MAX_FRAME_DEPTH 128

// Bitmask to strip pointer authentication (PAC).
#define PAC_STRIPPING_BITMASK 0x0000000FFFFFFFFF

typedef struct {
    /// Name of the associated library.
    // char name[64];
    /// The address itself.
    uint64_t address;
} backtrace_address_t;

typedef struct {
    /// Number of addresses in the backtrace.
    int length;
    /// The addresses of the backtrace.
    backtrace_address_t *addresses;
} backtrace_t;

backtrace_t get_backtrace(thread_t thread);

#endif /* get_backtrace_h */
