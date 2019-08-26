using System;
using Xunit;
using JacobianComparisonLib;

namespace JacobianComparisonLibTests
{
    public class DoubleComparisonTests
    {
        private const double defaultTolerance = 1e-6;

        [Fact]
        public void InfinityZeroDifference()
        {
            var diff = JacobianComparison.Difference(double.PositiveInfinity, double.PositiveInfinity);
            Assert.Equal(0.0, diff);
            diff = JacobianComparison.Difference(double.NegativeInfinity, double.NegativeInfinity);
            Assert.Equal(0.0, diff);
            diff = JacobianComparison.Difference(double.PositiveInfinity, double.NegativeInfinity);
            Assert.NotEqual(0.0, diff);
        }

        [Theory]
        [InlineData(0.1, 0.2)]
        [InlineData(1e-4, 2e-4)]
        [InlineData(1e-8, 2e-4)]
        [InlineData(double.Epsilon, 0.0)]
        [InlineData(1.0, 0.0)]
        [InlineData(0.5, 0.5)]
        public void DifferenceIsAbsoluteInZeroVicinity(double x, double y)
        {
            Assert.Equal(JacobianComparison.Difference(x, y), Math.Abs(x - y));
        }

        [Theory]
        [InlineData(1, 2)]
        [InlineData(1e4, 2e4)]
        [InlineData(1e8, -2e4)]
        [InlineData(double.Epsilon, 5.0)]
        [InlineData(2.0, 0.0)]
        [InlineData(0.7, -0.8)]
        public void DifferenceIsRelativeOutsideZeroVicinity(double x, double y)
        {
            Assert.Equal(JacobianComparison.Difference(x, y), Math.Abs(x - y) / (Math.Abs(x) + Math.Abs(y)));
        }

        [Theory]
        [InlineData(double.PositiveInfinity, double.PositiveInfinity, 0.0)]
        [InlineData(double.NegativeInfinity, double.NegativeInfinity, 0.0)]
        [InlineData(1e6, 1e6 + 1, defaultTolerance)]
        [InlineData(1e6 + 1, 1e6, defaultTolerance)]
        [InlineData(-1e6, -1e6 - 1, defaultTolerance)]
        [InlineData(-1e6 - 1, -1e6, defaultTolerance)]
        [InlineData(1.0, 1.0 + 1e-6, defaultTolerance)]
        [InlineData(1.0 + 1e-6, 1.0, defaultTolerance)]
        [InlineData(-1.0, -1.0 - 1e-6, defaultTolerance)]
        [InlineData(-1.0 - 1e-6, -1.0, defaultTolerance)]
        [InlineData(0.0, defaultTolerance, defaultTolerance)]
        [InlineData(defaultTolerance, double.Epsilon, defaultTolerance)]
        [InlineData(0.0, -defaultTolerance, defaultTolerance)]
        [InlineData(-defaultTolerance, -double.Epsilon, defaultTolerance)]
        [InlineData(double.Epsilon, -double.Epsilon, defaultTolerance)]
        [InlineData(double.Epsilon, 0.0, defaultTolerance)]
        [InlineData(0.0, -double.Epsilon, defaultTolerance)]
        [InlineData(defaultTolerance / 4, -defaultTolerance / 4, defaultTolerance)]
        [InlineData(0.2, 0.2 + defaultTolerance / 2, defaultTolerance)]
        [InlineData(0.2 + defaultTolerance / 2, 0.2, defaultTolerance)]
        [InlineData(-0.2, -0.2 - defaultTolerance / 2, defaultTolerance)]
        [InlineData(-0.2 - defaultTolerance / 2, -0.2, defaultTolerance)]
        [InlineData(double.MaxValue, double.MaxValue, defaultTolerance)]
        [InlineData(double.MinValue, double.MinValue, defaultTolerance)]
        public void ExpectedEquality(double x, double y, double tolerance)
        {
            var comparer = new JacobianComparison(tolerance);
            comparer.CompareNumbers(x, y, 0, 0);
            Assert.False(comparer.ViolationsHappened());
            Assert.Equal(0, comparer.DifferenceViolationCount);
            Assert.Equal(1, comparer.NumberComparisonCount);
        }

        [Theory]
        [InlineData(double.PositiveInfinity, double.NegativeInfinity, defaultTolerance)]
        [InlineData(1e6, 1e6 + 3, defaultTolerance)]
        [InlineData(1e4, 1e4 + 1, defaultTolerance)]
        [InlineData(1e4 + 1, 1e4, defaultTolerance)]
        [InlineData(-1e4, -1e4 - 1, defaultTolerance)]
        [InlineData(-1e4 - 1, -1e4, defaultTolerance)]
        [InlineData(1.0, 1.0 + 1e-4, defaultTolerance)]
        [InlineData(1.0 + 1e-4, 1.0, defaultTolerance)]
        [InlineData(-1.0, -1.0 - 1e-4, defaultTolerance)]
        [InlineData(-1.0 - 1e-4, -1.0, defaultTolerance)]
        [InlineData(0.0, -2 * defaultTolerance, defaultTolerance)]
        [InlineData(-2 * defaultTolerance, -double.Epsilon, defaultTolerance)]
        [InlineData(defaultTolerance, -defaultTolerance, defaultTolerance)]
        [InlineData(0.2, 0.2 + defaultTolerance * 2, defaultTolerance)]
        [InlineData(0.2 + defaultTolerance * 2, 0.2, defaultTolerance)]
        [InlineData(-0.2, -0.2 - defaultTolerance * 2, defaultTolerance)]
        [InlineData(-0.2 - defaultTolerance * 2, -0.2, defaultTolerance)]
        [InlineData(double.MaxValue, double.MaxValue / 2, defaultTolerance)]
        [InlineData(double.MinValue, double.MinValue / 2, defaultTolerance)]
        [InlineData(double.MaxValue, double.MinValue, defaultTolerance)]
        [InlineData(double.MaxValue, double.PositiveInfinity, defaultTolerance)]
        [InlineData(double.MinValue, double.NegativeInfinity, defaultTolerance)]
        [InlineData(double.NaN, double.PositiveInfinity, defaultTolerance)]
        [InlineData(double.NaN, double.NegativeInfinity, defaultTolerance)]
        [InlineData(double.NaN, double.MaxValue, defaultTolerance)]
        [InlineData(double.NaN, double.MinValue, defaultTolerance)]
        [InlineData(double.NaN, double.Epsilon, defaultTolerance)]
        [InlineData(double.NaN, 0.0, defaultTolerance)]
        [InlineData(double.NaN, defaultTolerance, defaultTolerance)]
        [InlineData(double.NaN, -defaultTolerance, defaultTolerance)]
        public void ExpectedInequality(double x, double y, double tolerance)
        {
            var comparer = new JacobianComparison(tolerance);
            comparer.CompareNumbers(x, y, 0, 0);
            Assert.True(comparer.ViolationsHappened());
            Assert.Equal(1, comparer.DifferenceViolationCount);
            Assert.Equal(1, comparer.NumberComparisonCount);
        }
    }
}
