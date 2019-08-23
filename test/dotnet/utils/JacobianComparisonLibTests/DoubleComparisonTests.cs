using System;
using Xunit;
using JacobianComparisonLib;

namespace JacobianComparisonLibTests
{
    public class DoubleComparisonTests
    {
        [Fact]
        public void InfinityEquality()
        {
            var diff = JacobianComparison.Difference(double.PositiveInfinity, double.PositiveInfinity);
            Assert.Equal(0.0, diff);
            diff = JacobianComparison.Difference(double.NegativeInfinity, double.NegativeInfinity);
            Assert.Equal(0.0, diff);
        }
    }
}
