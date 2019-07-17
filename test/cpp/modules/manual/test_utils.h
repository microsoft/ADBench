#pragma once

#include <algorithm>
#include <string>
#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/Benchmark.h"
#include "../../../../src/cpp/runner/Filepaths.h"

// Checks whether test_member_function func (calculateObjective or calculateJacobian)
// of the provided ITest<Input, Output> instance runs for different time when the supplied
// times parameter is different. To do so this function uses find_repeats_for_minimum_measurable_time
// function. It tries to find such a minimum_measurable_time that
// find_repeats_for_minimum_measurable_time will return a number of repeats other than 1 or
// measurable_time_not_achieved. If func ignores its times parameter, we won't be able to find it.
template<class Input, class Output>
bool can_objective_run_multiple_times(ITest<Input, Output>& test, const test_member_function<Input, Output> func)
{
    std::chrono::duration<double> minimum_measurable_time(0.05);
    auto result = find_repeats_for_minimum_measurable_time(minimum_measurable_time, test, func);
    while (result.repeats == 1)
    {
        // minimum_measurable_time * 2 ensures, that minimum_measurable_time * 2 will grow, while
        // result.total_time * 2 is a good guess for the time needed for at least 2 repeats
        minimum_measurable_time = std::max(minimum_measurable_time * 2, result.total_time * 2);
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