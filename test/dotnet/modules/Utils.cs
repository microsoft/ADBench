using DotnetRunner;
using DotnetRunner.Benchmarks;
using DotnetRunner.Data;
using System;
using System.Collections.Generic;
using System.Text;

namespace DotnetModulesTests
{
    static class Utils
    {
        // Checks whether Action<int> func (CalculateObjective or CalculateJacobian)
        // of the provided ITest<Input, Output> instance runs for different time when the supplied
        // times parameter is different. To do so this function uses Benchmark.FindRepeatsForMinimumMeasurableTime
        // function. It tries to find such a minimumMeasurableTime that
        // Benchmark.FindRepeatsForMinimumMeasurableTime will return a number of repeats other than 1 or
        // Benchmark.MeasurableTimeNotAchieved. If func ignores its times parameter, we won't be able to find it.
        public static bool CanObjectiveRunMultipleTimes(Action<int> func)
        {
            var minimumMeasurableTime = TimeSpan.FromSeconds(0.05);
            var result = Benchmark.FindRepeatsForMinimumMeasurableTime(minimumMeasurableTime, func);
            while (result.Repeats == 1)
            {
                // minimumMeasurableTime * 2 ensures, that minimumMeasurableTime * 2 will grow, while
                // result.total_time * 2 is a good guess for the time needed for at least 2 repeats
                minimumMeasurableTime = new TimeSpan(Math.Max(minimumMeasurableTime.Ticks * 2, result.TotalTime.Ticks * 2));
                result = Benchmark.FindRepeatsForMinimumMeasurableTime(minimumMeasurableTime, func);
            }
            return result.Repeats != Benchmark.MeasurableTimeNotAchieved;
        }
    }
}
