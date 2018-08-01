using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Microsoft.Research.AuDotNet
{
    /// <summary>
    /// Additions to System.Math
    /// </summary>
    public class Math
    {
        /// <summary>
        /// Return norm(a - b)^2
        /// </summary>
        /// <param name="a"></param>
        /// <param name="b"></param>
        /// <returns></returns>
        static public double Hypot2Diff(float[] a, float[] b)
        {
            double tot = 0;
            for (int i = 0; i < a.Length; ++i)
            {
                float d = a[i] - b[i];
                tot += d * d;
            }
            return tot;
        }

        /// <summary>
        /// Return dx^2 + dy^2
        /// </summary>
        /// <param name="dx"></param>
        /// <param name="dy"></param>
        /// <returns></returns>
        static public double Hypot2(double dx, double dy)
        {
            return dx * dx + dy * dy;
        }


        /// <summary>
        /// Throw a NotFiniteNumberException if x is inf or nan
        /// </summary>
        /// <param name="x">The x to which the above refers</param>
        static public void AssertFinite(double x)
        {
            if (Double.IsInfinity(x) || Double.IsNaN(x))
                throw new NotFiniteNumberException();
        }

    }
}
