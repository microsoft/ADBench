using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Linq.Expressions;

namespace Microsoft.Research.AuDotNet
{
    /// <summary>
    /// Easy-to-use Assert functions.   In particular, see the Assert(Expression...) method.
    /// </summary>
    public class Debug
    {

        /// <summary>
        /// Write test result, and accumulate test statistics.
        /// </summary>
        /// <param name="v"></param>
        /// <param name="msg"></param>
        static public void Assert(bool v, string msg)
        {
            if (!v)
                throw new Exception("Assertion failed [" + msg + "]");
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

    }
}
