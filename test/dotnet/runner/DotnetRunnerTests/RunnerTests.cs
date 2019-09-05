using DotnetRunner;
using DotnetRunner.Data;
using MockTest;
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
            var moduleLoader = new DotnetRunner.ModuleLoader(modulePath);
            Assert.True(moduleLoader.GetGMMTest() != null);
            Assert.True(moduleLoader.GetBATest() != null);
            Assert.True(moduleLoader.GetHandTest() != null);
            Assert.True(moduleLoader.GetLSTMTest() != null);
        }

        [Fact]
        public void TimeLimit()
        {
            var gmmTestMock = new Mock<ITest<GMMInput, GMMOutput>>();
            var gmmTest = gmmTestMock.Object;

            //Run_count guarantees total time greater than the time_limit
            var runCount = 100;
            var timeLimit = TimeSpan.FromSeconds(0.1);
            //executionTime should be more than minimumMeasurableTime 
            //because we can expect find_repeats_for_minimum_measurable_time to call calculate_objective function only once in that case.
            var minimumMeasurableTime = TimeSpan.FromSeconds(0); ;
            var executionTime = TimeSpan.FromSeconds(0.01); ;

            gmmTestMock.Setup(test => test.CalculateObjective(It.IsAny<int>()))
                       .Callback((int _) => System.Threading.Thread.Sleep(executionTime));

            /*measureShortestTime(minimumMeasurableTime, runCount, timeLimit, gmmTestMock, gmmTestMock.Ca);*/
            
            //Number of runs should be less then runCount variable because totalTime will be reached. 
            gmmTestMock.Verify(test => test.CalculateObjective(It.IsAny<int>()), Times.Between(1, (int)Math.Ceiling(timeLimit/executionTime), Range.Exclusive));

        }
    }
}
