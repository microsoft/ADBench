#include "memory_size.h"


#if defined(__linux__)
using namespace std;
#endif

size_t get_memory_size()
{
#if defined(_WIN32)
    MEMORYSTATUSEX status;
    status.dwLength = sizeof(status);
    GlobalMemoryStatusEx(&status);
    return (size_t)status.ullTotalPhys;
#elif defined(__linux__)
    struct sysinfo sys_info;
    size_t total_ram = 0;
    if (sysinfo(&sys_info) != -1)
        total_ram = ((size_t)sys_info.totalram * sys_info.mem_unit);
    return total_ram;
#else
    // Unknown OS
    return 0L;
#endif
}

    //FILE* meminfo = fopen("/proc/meminfo", "r");
    //if (meminfo == NULL)
    //    // handle error
    //
    //char line[256];
    //while (fgets(line, sizeof(line), meminfo))
    //{
    //    int ram;
    //    if (sscanf(line, "MemTotal: %d kB", &ram) == 1)
    //    {
    //        fclose(meminfo);
    //        return ram;
    //    }
    //}
    //
    //// If we got here, then we couldn't find the proper line in the meminfo file
    //fclose(meminfo);
    //return 0;