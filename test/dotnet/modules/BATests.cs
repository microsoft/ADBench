using DotnetRunner;
using DotnetRunner.Data;
using Xunit;

namespace DotnetModulesTests
{
    public class BATests
    {
        const double Epsilon = 1e-10;
        TolerantDoubleComparer comparer = TolerantDoubleComparer.FromTolerance(Epsilon);

        ModuleLoader moduleLoader = new ModuleLoader("./DiffSharpModule.dll");

        [Fact]
        public void Load()
        {
            var test = moduleLoader.GetBATest();
            Assert.NotNull(test);
        }

        [Fact]
        public void ObjectiveCalculationCorrectness()
        {
            var module = moduleLoader.GetBATest();
            Assert.NotNull(module);

            // Read instance
            var input = DataLoader.ReadBAInstance("batest.txt");

            module.Prepare(input);
            module.CalculateObjective(1);

            var output = module.Output();

            for (int i = 0; i < 20; i += 2)
            {
                Assert.Equal(-2.69048849235189402e-01, output.ReprojErr[i], comparer);
                Assert.Equal(2.59944792677901881e-01, output.ReprojErr[i + 1], comparer);
            }
            for (int i = 0; i < 10; i++)
            {
                Assert.Equal(8.26092651515999976e-01, output.WErr[i], comparer);
            }
        }

        [Fact]
        public void JacobianCalculationCorrectness()
        {
            var module = moduleLoader.GetBATest();
            Assert.NotNull(module);

            // Read instance
            var input = DataLoader.ReadBAInstance("batest.txt");

            module.Prepare(input);
            module.CalculateJacobian(1);

            var output = module.Output();
            Assert.Equal(30, output.J.nrows);
            Assert.Equal(62, output.J.ncols);
            Assert.Equal(31, output.J.rows.Count);
            Assert.Equal(310, output.J.cols.Count);
            Assert.Equal(310, output.J.vals.Count);
            Assert.Equal(2.28877202208246757e+02, output.J.vals[0], comparer);
            Assert.Equal(6.34574811495545418e+02, output.J.vals[1], comparer);
            Assert.Equal(-7.82222866259340549e+02, output.J.vals[2], comparer);
            Assert.Equal(2.42892615607159668e+00, output.J.vals[3], comparer);
            Assert.Equal(-1.17828079628011313e+01, output.J.vals[4], comparer);
            Assert.Equal(2.54169312487743460e+00, output.J.vals[5], comparer);
            Assert.Equal(-1.03657084958518086e+00, output.J.vals[6], comparer);
            Assert.Equal(4.17022000000000004e-01, output.J.vals[7], comparer);
            Assert.Equal(0.0, output.J.vals[8], comparer);
            Assert.Equal(-3.50739521096005205e+02, output.J.vals[9], comparer);
            Assert.Equal(-9.12107773668008576e+02, output.J.vals[10], comparer);
            Assert.Equal(-2.42892615607159668e+00, output.J.vals[11], comparer);
            Assert.Equal(1.17828079628011313e+01, output.J.vals[12], comparer);
            Assert.Equal(-8.34044000000000008e-01, output.J.vals[307], comparer);
            Assert.Equal(-8.34044000000000008e-01, output.J.vals[308], comparer);
            Assert.Equal(-8.34044000000000008e-01, output.J.vals[309], comparer);
        }

        [Fact]
        public void ObjectiveRunsMultipleTimes()
        {
            var module = moduleLoader.GetBATest();
            Assert.NotNull(module);

            // Read instance
            var input = DataLoader.ReadBAInstance("batest.txt");

            module.Prepare(input);

            Assert.True(Utils.CanObjectiveRunMultipleTimes(module.CalculateObjective));
        }

        [Fact]
        public void JacobianRunsMultipleTimes()
        {
            var module = moduleLoader.GetBATest();
            Assert.NotNull(module);

            // Read instance
            var input = DataLoader.ReadBAInstance("batest.txt");

            module.Prepare(input);

            Assert.True(Utils.CanObjectiveRunMultipleTimes(module.CalculateJacobian));
        }
                 
    }
}
