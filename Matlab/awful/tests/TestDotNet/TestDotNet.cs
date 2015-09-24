using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Text.RegularExpressions;

using Au = Microsoft.Research.AuDotNet;

namespace TestDotNet
{
    class TestDotNet
    {
        static void Main(string[] args)
        {
            // Check that Test.Assert prints a coloured message for failures
            {
                Au.Test.Assert(1 == 0, "This *should* fail");
                Au.Test.ResetStatistics();
            }

            // Check that Test.Assert prints a sensible message for expression inputs...
            {
                double x = 1.3;
                double y = 1.3;

                string test_output;
                using (StringWriter sw = new StringWriter())
                using (Au.TextWriterConsole twc = new Au.TextWriterConsole(sw))
                {
                    Au.Utils.PushConsole(twc);
                    Au.Test.Assert(() => x == y);
                    test_output = Regex.Replace(sw.ToString(), "[\n\r\t ]+$", "");
                    Au.Utils.PopConsole();
                }

                string desired_output = "TEST PASSED: x == y";
                Au.Test.Assert(test_output == desired_output, "Test of Test.Assert [test_output = \"" + desired_output + "\"]");
            }

            // Check 2D array IsValueEqual
            double[,] v = new double[3, 4];
            Au.Test.Assert(() => !Au.Utils.IsValueEqual(v, null));

            // Check 2D array fill
            Au.Utils.Fill(v, 2.3);
            Au.Test.Assert(() => v[1, 2] == 2.3);

            // Check array assignment
            v[1, 2] = 1.0;
            Au.Test.Assert(() => v[1, 2] == 1.0);

            double[,] check = new double[3, 4] { { 2.3, 2.3, 2.3, 2.3 }, { 2.3, 2.3, 1.0, 2.3 }, { 2.3, 2.3, 2.3, 2.3 } };
            Au.Test.Assert(() => Au.Utils.IsValueEqual(v, check));

            // Check 2D array load/save
            Au.Utils.Save(v, "tmp.txt");
            double[,] v1 = Au.Utils.LoadMatrix("tmp.txt");
            Au.Test.Assert(() => Au.Utils.IsValueEqual(v, v1));

            // Check Hypot2
            {
                double x = 1.3;
                double y = 2.3;
                Au.Test.Assert(() => x * x + y * y == Au.Math.Hypot2(x, y));
            }

            // Check CommonPrefix
            {
                Au.Test.Assert(() => Au.Utils.CommonPrefix(new string[] { "Piglet's", "Pigeon", "Pie" }) == "Pi");
                Au.Test.Assert(() => Au.Utils.CommonPrefix(new string[] { "Twiglet's", "Pigeon", "Pie" }) == "");
                Au.Test.Assert(() => Au.Utils.CommonPrefix(new string[] { }) == "");
                Au.Test.Assert(() => Au.Utils.CommonPrefix(new string[] { "a" }) == "a");
                Au.Test.Assert(() => Au.Utils.CommonPrefix(new string[] { "a", "a" }) == "a");
            }

            // Check GetVisualStudioInstanceBySolution to see that when asked for this solution, it returns one
            // containing a project named "TestDotNet"
            {
                EnvDTE.Solution sln = Au.DesignTime.GetVisualStudioInstanceBySolution(@"\\awful\.sln");
                Au.Test.Assert(() => sln != null);
                Au.Test.Assert(() => sln.Projects.Cast<EnvDTE.Project>().Any(p => p.Name == "TestDotNet"));
            }
            Au.Test.Summarize();

            // Some people have a readline here, but that changes behaviour between F5 and CTRL+F5.
            // Just put a breakpoint here instead.
        }
    }
}
