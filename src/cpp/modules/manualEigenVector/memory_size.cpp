#include "memory_size.h"

#if defined(_WIN32)
#include <windows.h>

#elif defined(__linux__)
#include <cstddef>
#include <sys/sysinfo.h>

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
    size_t total_ram = 0;
    if (sysinfo(&sys_info) != -1)
        total_ram = ((unsigned long long int)sys_info.totalram * sys_info.mem_unit);
    return total_ram;
#else
    // Unknown OS
    return 0L;
#endif
}