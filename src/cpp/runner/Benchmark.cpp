#include "Benchmark.h"

std::string filepath_to_basename(const std::string& filepath)
{
    const auto last_slash_position = filepath.find_last_of("/\\");
    const auto filename = last_slash_position == std::string::npos
                              ? filepath
                              : filepath.substr(last_slash_position + 1);

    const auto dot = filename.find_last_of('.');
    const auto basename = dot == std::string::npos
                              ? filename
                              : filename.substr(0, dot);

    return basename;
}
