using System;
using System.IO;
using System.Linq;

namespace DotnetRunner.Data
{
    public static class DataLoader
    {
        private static string[][] ReadInElements(string filepath)
        {
            var stringLines = File.ReadLines(filepath);
            char[] separators = { ' ' };

            return stringLines.Select(line => line.Split(separators)
                                                   .Where(x => x.Length > 0)
                                                   .ToArray()
                                      ).ToArray();
        }

        private static double[] ParseDoubleArray(string line) =>
            line.Split(' ')
            .Where(s => !string.IsNullOrWhiteSpace(s))
            .Select(s => double.Parse(s, System.Globalization.CultureInfo.InvariantCulture))
            .ToArray();

        public static GMMInput ReadGMMInstance(string inputFilePath, bool replicatePoint)
        {
            var input = new GMMInput();

            using (var line = File.ReadLines(inputFilePath).GetEnumerator())
            {
                line.MoveNext();
                var parts = line.Current.Split(' ');
                input.D = int.Parse(parts[0]);
                input.K = int.Parse(parts[1]);
                input.N = int.Parse(parts[2]);
                int icf_sz = input.D * (input.D + 1) / 2;

                input.Alphas = new double[input.K];
                for (int i = 0; i < input.K; ++i)
                {
                    line.MoveNext();
                    input.Alphas[i] = double.Parse(line.Current);
                }

                input.Means = new double[input.K][];
                for (int i = 0; i < input.K; ++i)
                {
                    line.MoveNext();
                    input.Means[i] = ParseDoubleArray(line.Current);
                }

                input.Icf = new double[input.K][];
                for (int i = 0; i < input.K; ++i)
                {
                    line.MoveNext();
                    input.Icf[i] = ParseDoubleArray(line.Current);
                }

                input.X = new double[input.N][];
                if (replicatePoint)
                {
                    line.MoveNext();
                    double[] x = ParseDoubleArray(line.Current);
                    for (int i = 0; i < input.N; ++i)
                    {
                        input.X[i] = x.ToArray();
                    }
                }
                else
                {
                    for (int i = 0; i < input.N; ++i)
                    {
                        line.MoveNext();
                        input.X[i] = ParseDoubleArray(line.Current);
                    }
                }

                line.MoveNext();
                parts = line.Current.Split(' ');
                Wishart wishart = new Wishart();
                wishart.Gamma = double.Parse(parts[0]);
                wishart.M = int.Parse(parts[1]);
                input.Wishart = wishart;
            }
            return input;
        }

        public static BAInput ReadBAInstance(string inputFilePath)
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

        public static LSTMInput ReadLSTMInstance(string inputFilePath)
        {
            var input = new LSTMInput();
            using (var line = File.ReadLines(inputFilePath).GetEnumerator())
            {
                line.MoveNext();
                var parts = line.Current.Split(' ');
                input.LayerCount = int.Parse(parts[0]);
                input.CharCount = int.Parse(parts[1]);
                input.CharBits = int.Parse(parts[2]);
                line.MoveNext();
                input.MainParams = new double[2 * input.LayerCount][];
                for (int i = 0; i < 2 * input.LayerCount; ++i)
                {
                    line.MoveNext();
                    input.MainParams[i] = ParseDoubleArray(line.Current);
                }
                line.MoveNext();
                input.ExtraParams = new double[3][];
                for (int i = 0; i < 3; ++i)
                {
                    line.MoveNext();
                    input.ExtraParams[i] = ParseDoubleArray(line.Current);
                }
                line.MoveNext();
                input.State = new double[2 * input.LayerCount][];
                for (int i = 0; i < 2 * input.LayerCount; ++i)
                {
                    line.MoveNext();
                    input.State[i] = ParseDoubleArray(line.Current);
                }
                line.MoveNext();
                input.Sequence = new double[input.CharCount][];
                for (int i = 0; i < input.CharCount; ++i)
                {
                    line.MoveNext();
                    input.Sequence[i] = ParseDoubleArray(line.Current);
                }
            }
            return input;
        }
    }
}
