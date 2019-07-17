#pragma once

#include <algorithm>
#include <string>
#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/Benchmark.h"
#include "../../../../src/cpp/runner/Filepaths.h"

template<class Input, class Output>
bool can_objective_run_multiple_times(ITest<Input, Output>& test, const test_member_function<Input, Output> func)
{
    std::chrono::duration<double> minimum_measurable_time(0.05);
    auto result = find_repeats_for_minimum_measurable_time(minimum_measurable_time, test, func);
    while (result.repeats == 1)
    {
        minimum_measurable_time = result.total_time * 2;
        result = find_repeats_for_minimum_measurable_time(minimum_measurable_time, test, func);
    }
    std::cout << result.repeats << std::endl;
    return result.repeats != measurable_time_not_achieved;
}

template<class T>
std::string get_module_name(const ::testing::TestParamInfo<T>& info)
{
    auto name = filepath_to_basename(std::string(info.param));
    int n = 0;
    name.erase(
        std::remove_if(name.begin(),
            name.end(),
            [](unsigned char x) {return !std::isalnum(x); }),
        name.end());
    return name;
}