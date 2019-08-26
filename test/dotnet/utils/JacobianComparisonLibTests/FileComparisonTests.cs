using System;
using Xunit;
using JacobianComparisonLib;

namespace JacobianComparisonLibTests
{
    public class FileComparisonTests
    {
        private const double defaultTolerance = 1e-6;
        private const string badData = "data/bad_data1.txt";
        private const string nonExist = "data/nonexistent.txt";
        private const string positions = "data/positions.txt";
        private const string alphas = "data/alphas.txt";
        private const string means = "data/means.txt";
        private const string icfs = "data/icfs.txt";
        private const string goodGmm = "data/gmm_grad_good.txt";
        private const string goodGmmExtraEmptyLines = "data/gmm_grad_good_extra_empty_lines.txt";
        private const string cutGmm = "data/gmm_grad_bad_length.txt";
        private const string badGmm = "data/gmm_grad_errors.txt";
        private const string jagged = "data/jagged.txt";
        private const string jaggedNear = "data/jagged_near.txt";
        private const string jaggedExtraWhitespace = "data/jagged_extra_whitespace.txt";
        private const string jaggedWrongDim = "data/jagged_dimension_mismatch.txt";
        private const string jaggedErrors = "data/jagged_errors.txt";

        [Theory]
        [InlineData(badData, positions, alphas, means, icfs)]
        [InlineData(goodGmm, badData, alphas, means, icfs)]
        [InlineData(goodGmm, positions, badData, means, icfs)]
        [InlineData(goodGmm, positions, alphas, badData, icfs)]
        [InlineData(goodGmm, positions, alphas, means, badData)]
        [InlineData(nonExist, positions, alphas, means, icfs)]
        [InlineData(goodGmm, nonExist, alphas, means, icfs)]
        [InlineData(goodGmm, positions, nonExist, means, icfs)]
        [InlineData(goodGmm, positions, alphas, nonExist, icfs)]
        [InlineData(goodGmm, positions, alphas, means, nonExist)]
        public void GmmParseErrors(string fullGrad, string positions, string alphas, string means, string icfs)
        {
            var comparer = new JacobianComparison(defaultTolerance);
            comparer.CompareGmmFullAndPartGradients(fullGrad, new[] { positions, alphas, means, icfs });
            Assert.True(comparer.ViolationsHappened());
            Assert.True(comparer.ParseError);
        }

        [Theory]
        [InlineData(badData, badData)]
        [InlineData(goodGmm, badData)]
        [InlineData(badData, goodGmm)]
        [InlineData(nonExist, nonExist)]
        [InlineData(goodGmm, nonExist)]
        [InlineData(nonExist, goodGmm)]
        public void JaggedArrayParseErrors(string x, string y)
        {
            var comparer = new JacobianComparison(defaultTolerance);
            comparer.CompareFiles(x, y);
            Assert.True(comparer.ViolationsHappened());
            Assert.True(comparer.ParseError);
        }

        [Theory]
        [InlineData(goodGmm)]
        [InlineData(goodGmmExtraEmptyLines)]
        public void GoodGmmPass(string goodGmm)
        {
            var comparer = new JacobianComparison(defaultTolerance);
            comparer.CompareGmmFullAndPartGradients(goodGmm, new[] { positions, alphas, means, icfs });
            Assert.False(comparer.ViolationsHappened());
            Assert.False(comparer.ParseError);
            Assert.False(comparer.DimensionMismatch);
            Assert.True(comparer.MaxDifference <= defaultTolerance);
            Assert.Equal(0, comparer.DifferenceViolationCount);
            Assert.Equal(15, comparer.NumberComparisonCount);
            Assert.Empty(comparer.DifferenceViolations);
        }

        [Fact]
        public void GmmDimensionMismatch()
        {
            var comparer = new JacobianComparison(defaultTolerance);
            comparer.CompareGmmFullAndPartGradients(cutGmm, new[] { positions, alphas, means, icfs });
            Assert.True(comparer.ViolationsHappened());
            Assert.False(comparer.ParseError);
            Assert.True(comparer.DimensionMismatch);
        }

        [Fact]
        public void GoodGmmFailOnSmallTolerance()
        {
            var comparer = new JacobianComparison(1e-8);
            comparer.CompareGmmFullAndPartGradients(goodGmm, new[] { positions, alphas, means, icfs });
            Assert.True(comparer.ViolationsHappened());
            Assert.False(comparer.ParseError);
            Assert.False(comparer.DimensionMismatch);
            Assert.True(comparer.MaxDifference <= defaultTolerance);
            Assert.True(comparer.DifferenceViolationCount > 0);
            Assert.Equal(15, comparer.NumberComparisonCount);
            Assert.NotEmpty(comparer.DifferenceViolations);
        }

        [Fact]
        public void BadGmmFail()
        {
            var comparer = new JacobianComparison(defaultTolerance);
            comparer.CompareGmmFullAndPartGradients(badGmm, new[] { positions, alphas, means, icfs });
            Assert.True(comparer.ViolationsHappened());
            Assert.False(comparer.ParseError);
            Assert.False(comparer.DimensionMismatch);
            Assert.False(comparer.MaxDifference <= defaultTolerance);
            Assert.Equal(8, comparer.DifferenceViolationCount);
            Assert.Equal(15, comparer.NumberComparisonCount);
            Assert.NotEmpty(comparer.DifferenceViolations);
            for (int i = 0; i < 15; i += 2)
                Assert.Contains((0, i), comparer.DifferenceViolations);
            for (int i = 1; i < 15; i += 2)
                Assert.DoesNotContain((0, i), comparer.DifferenceViolations);
        }

        [Theory]
        [InlineData(goodGmm, goodGmmExtraEmptyLines, 15)]
        [InlineData(jagged, jaggedExtraWhitespace, 15)]
        [InlineData(jaggedNear, jaggedExtraWhitespace, 15)]
        public void NearJaggedArraysPass(string x, string y, int expectedComparisons)
        {
            var comparer = new JacobianComparison(defaultTolerance);
            comparer.CompareFiles(x, y);
            Assert.False(comparer.ViolationsHappened());
            Assert.False(comparer.ParseError);
            Assert.False(comparer.DimensionMismatch);
            Assert.True(comparer.MaxDifference <= defaultTolerance);
            Assert.Equal(0, comparer.DifferenceViolationCount);
            Assert.Equal(expectedComparisons, comparer.NumberComparisonCount);
            Assert.Empty(comparer.DifferenceViolations);
        }

        [Theory]
        [InlineData(goodGmm, cutGmm)]
        [InlineData(jagged, jaggedWrongDim)]
        [InlineData(jaggedWrongDim, jaggedExtraWhitespace)]
        public void JaggedArrayDimensionMismatch(string x, string y)
        {
            var comparer = new JacobianComparison(defaultTolerance);
            comparer.CompareFiles(x, y);
            Assert.True(comparer.ViolationsHappened());
            Assert.False(comparer.ParseError);
            Assert.True(comparer.DimensionMismatch);
        }

        [Theory]
        [InlineData(goodGmm, badGmm, 15, defaultTolerance)]
        [InlineData(jagged, jaggedErrors, 15, defaultTolerance)]
        [InlineData(jaggedErrors, jaggedExtraWhitespace, 15, defaultTolerance)]
        [InlineData(jagged, jaggedNear, 15, 1e-8)]
        public void FarJaggedArraysFail(string x, string y, int expectedComparisons, double tolerance)
        {
            var comparer = new JacobianComparison(tolerance);
            comparer.CompareFiles(x, y);
            Assert.True(comparer.ViolationsHappened());
            Assert.False(comparer.ParseError);
            Assert.False(comparer.DimensionMismatch);
            Assert.False(comparer.MaxDifference <= tolerance);
            Assert.True(comparer.DifferenceViolationCount > 0);
            Assert.Equal(expectedComparisons, comparer.NumberComparisonCount);
            Assert.NotEmpty(comparer.DifferenceViolations);
        }

        [Fact]
        public void FarJaggedArraysViolationPositions()
        {
            var comparer = new JacobianComparison(defaultTolerance);
            comparer.CompareFiles(jaggedExtraWhitespace, jaggedErrors);
            Assert.True(comparer.ViolationsHappened());
            Assert.False(comparer.ParseError);
            Assert.False(comparer.DimensionMismatch);
            Assert.False(comparer.MaxDifference <= defaultTolerance);
            Assert.Equal(8, comparer.DifferenceViolationCount);
            Assert.Equal(15, comparer.NumberComparisonCount);
            Assert.NotEmpty(comparer.DifferenceViolations);
            var expectedViolations = new[] { (0, 0), (1, 1), (3, 1), (0, 2), (2, 2), (0, 3), (2, 3), (4, 3) };
            Assert.Equal(expectedViolations, comparer.DifferenceViolations);
        }
    }
}
