using DotnetRunner;
using DotnetRunner.Data;
using DotnetRunner.Benchmarks;
using Moq;
using System;
using System.IO;
using Xunit;

namespace DotnetRunnerTests
{
    public class RunnerTests
    {
        [Fact]
        public void LibraryLoadTest()
        {
            var modulePath = Path.Combine(Directory.GetCurrentDirectory(), "MockTest.dll");
            using (var moduleLoader = new ModuleLoader(modulePath))
            {
                Assert.True(moduleLoader.GetBATest() != null);
                Assert.True(moduleLoader.GetBATest() != null);
                Assert.True(moduleLoader.GetHandTest() != null);
                Assert.True(moduleLoader.GetLSTMTest() != null);
            }
        }

        [Fact]
        public void TimeLimit()
        {
            var baTestMock = new Mock<ITest<BAInput, BAOutput>>();
            var baTest = baTestMock.Object;

            //runCount guarantees totalTime greater than the timeLimit
            var runCount = 100;
            var timeLimit = TimeSpan.FromSeconds(0.1);
            //executionTime should be more than minimumMeasurableTime 
            //because we can expect FindRepeatsForMinimumMeasurableTime to call CalculateObjective function only once in that case.
            var minimumMeasurableTime = TimeSpan.Zero;
            var executionTime = TimeSpan.FromSeconds(0.01); ;

            baTestMock.Setup(test => test.CalculateObjective(It.IsAny<int>()))
                       .Callback((int _) => System.Threading.Thread.Sleep(executionTime));

            Benchmark.MeasureShortestTime(minimumMeasurableTime, runCount, timeLimit, baTest.CalculateObjective);

            //Number of runs should be less then runCount variable because totalTime will be reached. 
            baTestMock.Verify(test => test.CalculateObjective(It.IsAny<int>()), Times.Between(1, (int)Math.Ceiling(timeLimit / executionTime), Range.Exclusive));
        }

        [Fact]
        public void NumberOfRunsLimit()
        {
            var baTestMock = new Mock<ITest<BAInput, BAOutput>>();
            var baTest = baTestMock.Object;

            var minimumMeasurableTime = TimeSpan.Zero;
            var runCount = 10;
            var timeLimit = TimeSpan.FromSeconds(10);
            var executionTime = TimeSpan.FromSeconds(0.01);

            baTestMock.Setup(test => test.CalculateObjective(It.IsAny<int>()))
                       .Callback((int _) => System.Threading.Thread.Sleep(executionTime));

            Benchmark.MeasureShortestTime(minimumMeasurableTime, runCount, timeLimit, baTest.CalculateObjective);

            //Number of runs should be equal to runCount limit.
            baTestMock.Verify(test => test.CalculateObjective(It.IsAny<int>()), Times.Exactly(runCount));
        }

        [Fact]
        public void TimeMeasurement()
        {
            var baTestMock = new Mock<ITest<BAInput, BAOutput>>();
            var baTest = baTestMock.Object;

            var minimumMeasurableTime = TimeSpan.Zero;
            var runCount = 10;
            var timeLimit = TimeSpan.FromSeconds(100000);
            var executionTime = TimeSpan.FromSeconds(0.01);

            baTestMock.Setup(test => test.CalculateObjective(It.IsAny<int>()))
                       .Callback((int _) => System.Threading.Thread.Sleep(executionTime));

            var shortestTime = Benchmark.MeasureShortestTime(minimumMeasurableTime, runCount, timeLimit, baTest.CalculateObjective);

            baTestMock.Verify(test => test.CalculateObjective(It.IsAny<int>()), Times.Exactly(runCount));

            Assert.True(shortestTime >= executionTime);
        }

        [Fact]
        public void SearchForRepeats()
        {
            var baTestMock = new Mock<ITest<BAInput, BAOutput>>();
            var baTest = baTestMock.Object;

            var assumedRepeats = 16;
            var executionTime = TimeSpan.FromSeconds(0.01);
            var minimumMeasurableTime = executionTime * assumedRepeats;

            baTestMock.Setup(test => test.CalculateObjective(It.IsAny<int>()))
                       .Callback((int repeats) => System.Threading.Thread.Sleep(repeats * executionTime));

            var result = Benchmark.FindRepeatsForMinimumMeasurableTime(minimumMeasurableTime, baTest.CalculateObjective);

            Assert.NotEqual(result.Repeats, Benchmark.MeasurableTimeNotAchieved);
            Assert.True(result.Repeats <= assumedRepeats);
        }

        [Fact]
        public void RepeatsNotFound()
        {
            var baTestMock = new Mock<ITest<BAInput, BAOutput>>();
            var baTest = baTestMock.Object;

            var minimumMeasurableTime = TimeSpan.FromSeconds(1000);

            var result = Benchmark.FindRepeatsForMinimumMeasurableTime(minimumMeasurableTime, baTest.CalculateObjective);

            Assert.Equal(result.Repeats, Benchmark.MeasurableTimeNotAchieved);
        }
    }
}
