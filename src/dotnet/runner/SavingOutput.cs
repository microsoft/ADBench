using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using DotnetRunner.Data;
using System.Linq;

namespace DotnetRunner
{
    public static class SavingOutput
    {
        public static string Format(double x) => x.ToString("g12", System.Globalization.CultureInfo.InvariantCulture);
        public static string Format(int x) => x.ToString(System.Globalization.CultureInfo.InvariantCulture);

        public static void SaveTimeToFile(string filepath, TimeSpan objectiveTime, TimeSpan derivativeTime)
        {
            var text = $"{Format(objectiveTime.TotalSeconds)}\n{Format(derivativeTime.TotalSeconds)}";
            File.WriteAllText(filepath, text);
        }

        public static void SaveValueToFile(string filepath, double value)
        {
            File.WriteAllText(filepath, Format(value));
        }

        public static void SaveVectorToFile(string filepath, double[] v)
        {
            using (var file = new StreamWriter(filepath))
            {
                foreach (var i in v)
                {
                    file.WriteLine(Format(i));
                };
            }
        }

        public static void SaveMatrixToFile(string filepath, double[][] v)
        {
            using (var file = new StreamWriter(filepath))
            {
                foreach (var i in v)
                {
                    file.WriteLine(string.Join('\t', i.Select(Format)));
                };
            }
        }

        public static void SaveErrorsToFile(string filepath, double[] reprojectionError, double[] zachWeightError)
        {
            using (var file = new StreamWriter(filepath))
            {
                file.WriteLine("Reprojection error:");

                foreach (var i in reprojectionError)
                {
                    file.WriteLine(Format(i));
                };

                file.WriteLine("Zach weight error:");

                foreach (var i in zachWeightError)
                {
                    file.WriteLine(Format(i));
                };
            }
        }

        public static void SaveSparseJToFile(string filepath, BASparseMatrix j)
        {
            using (var file = new StreamWriter(filepath))
            {
                file.WriteLine($"{Format(j.NRows)} {Format(j.NCols)}");
                file.WriteLine(Format(j.Rows.Count));
                file.WriteLine(string.Join(' ', j.Rows.Select(Format)));
                file.WriteLine(j.Cols.Count);
                file.WriteLine(string.Join(' ', j.Cols.Select(Format)));
                file.Write(string.Join(' ', j.Vals.Select(Format)));
            }
        }

        public static string ObjectiveFileName(string outputPrefix, string inputBasename, string moduleBasename)
        {
            return $"{outputPrefix}{inputBasename}_F_{moduleBasename}.txt";
        }

        public static string JacobianFileName(string outputPrefix, string inputBasename, string moduleBasename)
        {
            return $"{outputPrefix}{inputBasename}_J_{moduleBasename}.txt";
        }
    }
}
