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
            Assert.True(moduleLoader.GMMTest != null);
            Assert.True(moduleLoader.BATest != null);
            Assert.True(moduleLoader.HandTest != null);
            Assert.True(moduleLoader.LSTMTest != null);

        }
    }
}
