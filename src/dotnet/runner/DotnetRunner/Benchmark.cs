using System;
using System.Collections.Generic;
using System.Text;

namespace DotnetRunner
{
    static class Benchmark
    {
        public static void Run<Input,Output,Parameters>(string modulePath, string inputFilePath, string outputPrefix, TimeSpan minimumMeasurableTime, int nrunsF, int nrunsJ,
                   TimeSpan timeLimit, Parameters parameters)
        {

            var moduleLoader = new ModuleLoader(modulePath);
            var test = GetTest<Input, Output>(moduleLoader);
            var inputs = ReadInputData<Input, Parameters>(inputFilePath, parameters);

            test.Prepare(inputs);

             var objectiveTime =
                 measureShortestTime(minimumMeasurableTime, nrunsF, timeLimit, test, test.CalculateObjective);

             var derivativeTime =
                 measureShortestTime(minimumMeasurableTime, nrunsF, timeLimit, test, test.CalculateJacobian);

            var output = test.Output();

             var inputBasename = FilePathToBasename(inputFilePath);
             var moduleBasename = FilePathToBasename(modulePath);

             SaveTimeToFile(outputPrefix + inputBasename + "_times_" + moduleBasename + ".txt", objectiveTime, derivativeTime);
             SaveOutputToFile(output, outputPrefix, inputBasename, moduleBasename);
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

        private static TimeSpan measureShortestTime<Input, Output>(TimeSpan minimumMeasurableTime, int nrunsF, TimeSpan timeLimit, ITest<Input, Output> test, Action<int> calculateObjective)
        {
            throw new NotImplementedException();
        }

        private static Input ReadInputData<Input, Parameters>(string inputFilePath, Parameters parameters)
        {
            throw new NotImplementedException();
        }

        private static ITest<Input,Output> GetTest<Input, Output>(ModuleLoader moduleLoader)
        {
            throw new NotImplementedException();
        }
    }
}

