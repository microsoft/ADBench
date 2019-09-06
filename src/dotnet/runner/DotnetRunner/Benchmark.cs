using System;
using System.Collections.Generic;
using System.Text;

namespace DotnetRunner
{
    public static class Benchmark
    {
        public static readonly int MeasurableTimeNotAchieved = -1;

        public static void Run<Input, Output, Parameters>(string modulePath, string inputFilePath, string outputPrefix, TimeSpan minimumMeasurableTime, int nrunsF, int nrunsJ,
                   TimeSpan timeLimit, Parameters parameters)
        {

            var moduleLoader = new ModuleLoader(modulePath);
            var test = GetTest<Input, Output>(moduleLoader);
            var inputs = ReadInputData<Input, Parameters>(inputFilePath, parameters);

            test.Prepare(inputs);

            var objectiveTime =
                MeasureShortestTime(minimumMeasurableTime, nrunsF, timeLimit, test.CalculateObjective);

            var derivativeTime =
                MeasureShortestTime(minimumMeasurableTime, nrunsF, timeLimit, test.CalculateJacobian);

            var output = test.Output();

            var inputBasename = FilePathToBasename(inputFilePath);
            var moduleBasename = FilePathToBasename(modulePath);

            SaveTimeToFile(outputPrefix + inputBasename + "_times_" + moduleBasename + ".txt", objectiveTime, derivativeTime);
            SaveOutputToFile(output, outputPrefix, inputBasename, moduleBasename);
        }
        struct DefaultParameters { };

        public static void Run<Input, Output>(string modulePath, string inputFilePath, string outputPrefix, TimeSpan minimumMeasurableTime, int nrunsF, int nrunsJ,
                   TimeSpan timeLimit)
        {
            Run<Input, Output, DefaultParameters>(modulePath, inputFilePath, outputPrefix, minimumMeasurableTime, nrunsF, nrunsJ, timeLimit, new DefaultParameters());
        }

        private static void SaveOutputToFile<Output>(Output output, string outputPrefix, string input_basename, string module_basename)
        {
            throw new NotImplementedException();
        }

        private static void SaveTimeToFile(string v, TimeSpan objectiveTime, TimeSpan derivativeTime)
        {
            throw new NotImplementedException();
        }

        private static string FilePathToBasename(string inputFilePath)
        {
            throw new NotImplementedException();
        }

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

        private const int maxPossiblePowerOfTwo = (int.MaxValue >> 1) + 1;
        public static (int Repeats, TimeSpan Sample, TimeSpan TotalTime) FindRepeatsForMinimumMeasurableTime(TimeSpan minimumMeasurableTime, Action<int> func)
        {
            var totalTime = TimeSpan.Zero;
            var minSample = TimeSpan.MaxValue;

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

            return ( repeats, minSample, totalTime );
        }

        private static Input ReadInputData<Input, Parameters>(string inputFilePath, Parameters parameters)
        {
            throw new NotImplementedException();
        }

        private static ITest<Input, Output> GetTest<Input, Output>(ModuleLoader moduleLoader)
        {
            throw new NotImplementedException();
        }
    }
}

