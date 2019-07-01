#include "Filepaths.h"

std::string::size_type last_slash_position(const std::string& filepath)
{
    return filepath.find_last_of("/\\");
}

std::string filepath_to_basename(const std::string& filepath)
{
    const auto last_slash_position = last_slash_position(filepath);
    const auto filename = last_slash_position == std::string::npos
        ? filepath
        : filepath.substr(last_slash_position + 1);

    const auto dot = filename.find_last_of('.');
    const auto basename = dot == std::string::npos
        ? filename
        : filename.substr(0, dot);

    return basename;
}

std::string filepath_to_dirname(const std::string& filepath)
{
    const auto last_slash_position = last_slash_position(filepath);
    const auto dirname = last_slash_position == std::string::npos
        ? "./"
        : filepath.substr(0,last_slash_position);

    return dirname;
}