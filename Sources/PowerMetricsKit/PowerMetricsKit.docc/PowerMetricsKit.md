#  ``PowerMetricsKit``

A package to retrieve realtime information on CPU energy consumption using the CPU's Closed Loop Performance Controller (CLPC) via `proc_pidinfo`.

## Overview

This package uses `libproc`'s `proc_pidinfo` with the `PROC_PIDTHREADCOUNTS` option, which returns a `struct` including per-thread energy measurements from the CPU's' Closed Loop Performance Controller (CLPC), which in turn obtains the energy results from the Digital Power Estimator (DPE). 
The list of all threads is retrieved using `task_threads` with the PID of the current task (root privileges are required to invoke `task_threads` on other processes).

The `libproc.h` headers can't be imported on iOS, so they're reproduced at the beginning of `sample_threads.c`, as well as the result `struct`s from the `proc_pidinfo`, using the definitions and documentation available in [Apple's OSS Distributions repository for `libproc.h`](https://github.com/apple-oss-distributions/xnu/blob/aca3beaa3dfbd42498b42c5e5ce20a938e6554e5/bsd/sys/proc_info.h).
