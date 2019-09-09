using DotnetRunner.Data;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace DotnetRunner.Benchmarks
{
    class BABenchmark : Benchmark<BAInput, BAOutput>
    {
        private string[][] ReadInElements(string filepath)
        {
            var stringLines = File.ReadLines(filepath);
            char[] separators = { ' ' };

            return stringLines.Select(line => line.Split(separators)
                                                   .Where(x => x.Length > 0)
                                                   .ToArray()
                                      ).ToArray();
        }

        protected override BAInput ReadInputData(string inputFilePath, DefaultParameters parameters)
        {
            var input = new BAInput();

            var data = ReadInElements(inputFilePath);

            input.N = int.Parse(data[0][0]);
            input.M = int.Parse(data[0][1]);
            input.P = int.Parse(data[0][2]);

            Func<string[], double[]> getDoubles = (line => line.Select(double.Parse).ToArray());
            Func<double[], int, double[][]> clone = ((arr, times) => Enumerable.Range(1, times).Select(_ => arr).ToArray());

            var oneCam = getDoubles(data[1]);
            input.Cams = clone(oneCam, input.N);

            var oneX = getDoubles(data[2]);
            input.X = clone(oneX, input.M);

            var oneW = data[3].Select(double.Parse).First();
            input.W = Enumerable.Range(1, input.P).Select(_ => oneW).ToArray();

            var oneFeat = getDoubles(data[4]);
            input.Feats = clone(oneFeat, input.P);

            //camIdx = i % input.N
            //ptIdx = i % input.M
            input.Obs = Enumerable.Range(1, input.P)
                                  .Select(i => i - 1)
                                  .Select(i => new int[] { (i % input.N), (i % input.M) })
                                  .ToArray();

            return input;
        }

        protected override ITest<BAInput, BAOutput> GetTest(ModuleLoader moduleLoader)
        {
            return moduleLoader.GetBATest();
        }

        protected override void SaveOutputToFile(BAOutput output, string outputPrefix, string input_basename, string module_basename)
        {
            throw new NotImplementedException();
        }
    }
}
