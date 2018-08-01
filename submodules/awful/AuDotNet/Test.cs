using System;
using System.Collections.Generic;
using System.Linq.Expressions;
using System.Text;
using System.Text.RegularExpressions;

namespace Microsoft.Research.AuDotNet
{
    /// <summary>
    /// A set of assert methods which store the total number of failures,
    /// and a final Summarize() which prints them.
    /// </summary>
    public class Test
    {
        static int NumberOfFailures;
        static int NumberOfAsserts;

        /// <summary>
        /// Initialize test statistics
        /// </summary>
        static public void Init()
        {
            ResetStatistics();
        }

        /// <summary>
        /// Reset test statistics
        /// </summary>
        public static void ResetStatistics()
        {
            NumberOfAsserts = 0;
            NumberOfFailures = 0;
        }

        /// <summary>
        /// Write test result, and accumulate test statistics.
        /// </summary>
        /// <param name="v"></param>
        /// <param name="msg"></param>
        static public void Assert(bool v, string msg)
        {
            ++NumberOfAsserts;
            if (v)
                Utils.WriteLine("TEST PASSED: " + msg);
            else
            {
                Utils.WriteLine(ConsoleColor.Magenta, "TEST FAILED: " + msg);
                ++NumberOfFailures;
            }
        }

        /// <summary>
        /// Write test result.   The associated message is the string representation of the expression, so
        /// one can write e.g.
        ///  <code>
        ///  Au.Test.Assert(() => x == y)
        ///  </code>
        /// and the message printed will be
        ///  <code>
        ///  TEST PASSED: x == y 
        ///  </code>
        /// </summary>
        /// <param name="f"></param>
        static public void Assert(Expression<Func<bool>> f)
        {
            Assert(f.Compile()(), Utils.ToString(f));
        }

        /// <summary>
        /// Print summary statistics
        /// </summary>
        static public void Summarize()
        {
            if (NumberOfFailures == 0)
            {
                Utils.WriteLine("SUCCESS: All " + NumberOfAsserts + " tests succeeded");
            }
            else
            {
                Utils.WriteLine(ConsoleColor.Magenta, "FAILURE: " + NumberOfFailures + " out of " + NumberOfAsserts + " tests failed.");
            }
        }

    }
}
