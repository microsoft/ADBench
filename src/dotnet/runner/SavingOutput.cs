using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using DotnetRunner.Data;

namespace DotnetRunner
{
    public static class SavingOutput
    {
        public static void SaveTimeToFile(string filepath, TimeSpan objectiveTime, TimeSpan derivativeTime)
        {
            var line = objectiveTime.TotalSeconds.ToString() + "\n" + derivativeTime.TotalSeconds.ToString();
            File.WriteAllText(filepath, line);
        }

        internal static void SaveErrorsToFile(string filepath, double[] reprojectionError, double[] zachWeightError)
        {
            using (var file = new StreamWriter(filepath))
            {
                file.WriteLine("Reprojection error:");

                foreach (var i in reprojectionError)
                {
                    file.WriteLine(i);
                };

                file.WriteLine("Zach weight error:");

                foreach (var i in zachWeightError)
                {
                    file.WriteLine(i);
                };
            }
        }

        internal static void SaveSparseJToFile(string filepath, BASparseMatrix j)
        {
            using (var file = new StreamWriter(filepath))
            {
                file.WriteLine(j.nrows + " " + j.ncols);

                file.WriteLine(j.rows.Count);

                foreach (var row in j.rows)
                {
                    file.Write(row + " ");
                }
                file.WriteLine();

                file.WriteLine(j.cols.Count);

                foreach (var col in j.cols)
                {
                    file.Write(col + " ");
                }
                file.WriteLine();

                foreach (var val in j.vals)
                {
                    file.Write(val + " ");
                }
            }
        }

        internal static string ObjectiveFileName(string outputPrefix, string inputBasename, string moduleBasename)
        {
            return outputPrefix + inputBasename + "_F_" + moduleBasename + ".txt";
        }

        internal static string JacobianFileName(string outputPrefix, string inputBasename, string moduleBasename)
        {
            return outputPrefix + inputBasename + "_J_" + moduleBasename + ".txt";
        }
    }
}
