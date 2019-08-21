#pragma once

#if defined(_WIN32)
#include <windows.h>

#elif defined(__linux__)
#include <cstddef>
#include <sys/sysinfo.h>
using namespace std;

#else
#error "Cannot define size of memory for current OS."
#endif

// Returns the size of physical memory (RAM) in bytes.
size_t get_memory_size();