using DotnetRunner.Data;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace DotnetRunner.Benchmarks
{
    public struct DefaultParameters { };

    public abstract class Benchmark
    {
        public static readonly int MeasurableTimeNotAchieved = -1;

        private const int maxPossiblePowerOfTwo = (int.MaxValue >> 1) + 1;

        /// <summary>
        /// Finds the number of repeats that <paramref name="func"/> needs to be asked to compute its objective
        /// in order to to run for at least <paramref name="minimumMeasurableTime"/>.
        /// </summary>
        /// <returns>Returns a tuple (Repeats, Sample, TotalTime), where
        /// Repeats is the found necessary number of repeats;
        /// Sample is the minimal encountered value of
        /// runtime of <paramref name="func"/>(repeats) divided by repeats;
        /// TotalTime is the total time spent on running <paramref name="func"/> in seconds.</returns>
        public static (int Repeats, TimeSpan Sample, TimeSpan TotalTime) FindRepeatsForMinimumMeasurableTime(TimeSpan minimumMeasurableTime, Action<int> func)
        {
            var totalTime = TimeSpan.Zero;
            var minSample = TimeSpan.MaxValue;

            //Ensure that func is already compiled by JIT compiler
            System.Runtime.CompilerServices.RuntimeHelpers.PrepareMethod(func.Method.MethodHandle);
            var repeats = 1;
            var sw = new System.Diagnostics.Stopwatch();
            do
            {
                sw.Start();
                func(repeats);
                sw.Stop();
                //Time in seconds
                var currentRunTime = sw.Elapsed;
                if (currentRunTime > minimumMeasurableTime)
                {
                    var currentSample = currentRunTime / repeats;
                    minSample = new TimeSpan(Math.Min(minSample.Ticks, currentSample.Ticks));
                    totalTime += currentRunTime;
                    break;
                }
                //The next iteration will overflow a loop counter that's why we recognize that we cannot reach the minimum measurable time.
                if (repeats == maxPossiblePowerOfTwo)
                {
                    repeats = MeasurableTimeNotAchieved;
                    break;
                }
                repeats *= 2;
            } while (repeats <= maxPossiblePowerOfTwo);

            return (repeats, minSample, totalTime);
        }

        /// <summary>
        /// Benchmarks <paramref name="func"/> according to the methodology described in docs/Methodology.md
        /// </summary>
        public static TimeSpan MeasureShortestTime(TimeSpan minimumMeasurableTime, int nruns, TimeSpan timeLimit, Action<int> func)
        {
            var findRepeatsResult = FindRepeatsForMinimumMeasurableTime(minimumMeasurableTime, func);

            if (findRepeatsResult.Repeats == MeasurableTimeNotAchieved)
            {
                throw new Exception("It was not possible to reach the number of repeats sufficient to achieve the minimum measurable time.");
            }

            var repeats = findRepeatsResult.Repeats;
            var minSample = findRepeatsResult.Sample;
            var totalTime = findRepeatsResult.TotalTime;

            var sw = new System.Diagnostics.Stopwatch();
            // "run" begins from 1 because a first run already done by "findRepeatsForMinimumMeasurableTime" function
            for (var run = 1; (run < nruns) && (totalTime < timeLimit); run++)
            {
                sw.Start();
                func(repeats);
                sw.Stop();
                //Time in seconds
                var currentRunTime = sw.Elapsed;
                minSample = new TimeSpan(Math.Min(minSample.Ticks, currentRunTime.Ticks / repeats));
                totalTime += currentRunTime;
            }

            return minSample;
        }


    }

    public abstract class Benchmark<Input, Output, Parameters> : Benchmark
    {
        protected abstract Input ReadInputData(string inputFilePath, Parameters parameters);

        /// <summary>
        /// Performs the entire benchmark process according to the methodology described in docs/Methodology.md
        /// </summary>
        public void Run(string modulePath, string inputFilePath, string outputPrefix, TimeSpan minimumMeasurableTime, int nrunsF, int nrunsJ,
                   TimeSpan timeLimit, Parameters parameters)
        {
            using (var moduleLoader = new ModuleLoader(modulePath))
            {
                var test = GetTest(moduleLoader);
                var inputs = ReadInputData(inputFilePath, parameters);

                test.Prepare(inputs);

                var objectiveTime =
                    MeasureShortestTime(minimumMeasurableTime, nrunsF, timeLimit, test.CalculateObjective);

                var derivativeTime =
                    MeasureShortestTime(minimumMeasurableTime, nrunsJ, timeLimit, test.CalculateJacobian);

                var output = test.Output();

                var inputBasename = Path.GetFileNameWithoutExtension(inputFilePath);
                var moduleBasename = Path.GetFileNameWithoutExtension(modulePath);

                SavingOutput.SaveTimeToFile(outputPrefix + inputBasename + "_times_" + moduleBasename + ".txt", objectiveTime, derivativeTime);
                SaveOutputToFile(output, outputPrefix, inputBasename, moduleBasename);
            }
        }

        protected abstract void SaveOutputToFile(Output output, string outputPrefix, string input_basename, string module_basename);

        protected abstract ITest<Input, Output> GetTest(ModuleLoader moduleLoader);
    }

    public abstract class Benchmark<Input, Output> : Benchmark<Input, Output, DefaultParameters>
    {
        internal void Run(string modulePath, string inputFilePath, string outputPrefix, TimeSpan minimumMeasurableTime, int nrunsF, int nrunsJ, TimeSpan timeLimit)
        {
            Run(modulePath, inputFilePath, outputPrefix, minimumMeasurableTime, nrunsF, nrunsJ, timeLimit, new DefaultParameters { });
        }
    }

}

