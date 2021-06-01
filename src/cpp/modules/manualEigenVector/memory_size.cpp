// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "memory_size.h"

#if defined(_WIN32)
#include <windows.h>

#elif defined(__linux__)
#include <cstddef>
#include <sys/sysinfo.h>

#elif defined(__APPLE__)
#include <sys/types.h>
#include <sys/sysctl.h>

#else
#error "Cannot define size of memory for current OS."
#endif

unsigned long long int get_memory_size()
{
#if defined(_WIN32)
    MEMORYSTATUSEX status;
    status.dwLength = sizeof(status);
    GlobalMemoryStatusEx(&status);
    return (unsigned long long int)status.ullTotalPhys;
#elif defined(__linux__)
    struct sysinfo sys_info;
    unsigned long long int total_ram = 0;
    if (sysinfo(&sys_info) != -1)
        total_ram = ((unsigned long long int)sys_info.totalram * sys_info.mem_unit);
    return total_ram;
#elif defined(__APPLE__)
    int64_t memsize;
    size_t len = sizeof(memsize);
    sysctlbyname("hw.memsize", &memsize, &len, NULL, 0);
    return memsize;
#else
    // Unknown OS
    return 0L;
#endif
}
