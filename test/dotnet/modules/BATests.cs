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

        // helper methods
        public void CheckObjectiveCalculation(int times)
        {
            var module = moduleLoader.GetBATest();
            Assert.NotNull(module);

            // Read instance
            var input = DataLoader.ReadBAInstance("batest.txt");

            module.Prepare(input);
            module.CalculateObjective(times);

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

        void CheckJacobianCalculation(int times)
        {
            var module = moduleLoader.GetBATest();
            Assert.NotNull(module);

            // Read instance
            var input = DataLoader.ReadBAInstance("batest.txt");

            module.Prepare(input);
            module.CalculateJacobian(times);

            var output = module.Output();
            Assert.Equal(30, output.J.NRows);
            Assert.Equal(62, output.J.NCols);
            Assert.Equal(31, output.J.Rows.Count);
            Assert.Equal(310, output.J.Cols.Count);
            Assert.Equal(310, output.J.Vals.Count);
            Assert.Equal(2.28877202208246757e+02, output.J.Vals[0], comparer);
            Assert.Equal(6.34574811495545418e+02, output.J.Vals[1], comparer);
            Assert.Equal(-7.82222866259340549e+02, output.J.Vals[2], comparer);
            Assert.Equal(2.42892615607159668e+00, output.J.Vals[3], comparer);
            Assert.Equal(-1.17828079628011313e+01, output.J.Vals[4], comparer);
            Assert.Equal(2.54169312487743460e+00, output.J.Vals[5], comparer);
            Assert.Equal(-1.03657084958518086e+00, output.J.Vals[6], comparer);
            Assert.Equal(4.17022000000000004e-01, output.J.Vals[7], comparer);
            Assert.Equal(0.0, output.J.Vals[8], comparer);
            Assert.Equal(-3.50739521096005205e+02, output.J.Vals[9], comparer);
            Assert.Equal(-9.12107773668008576e+02, output.J.Vals[10], comparer);
            Assert.Equal(-2.42892615607159668e+00, output.J.Vals[11], comparer);
            Assert.Equal(1.17828079628011313e+01, output.J.Vals[12], comparer);
            Assert.Equal(-8.34044000000000008e-01, output.J.Vals[307], comparer);
            Assert.Equal(-8.34044000000000008e-01, output.J.Vals[308], comparer);
            Assert.Equal(-8.34044000000000008e-01, output.J.Vals[309], comparer);
        }

        [Fact]
        public void Load()
        {
            var test = moduleLoader.GetBATest();
            Assert.NotNull(test);
        }

        [Fact]
        public void ObjectiveCalculationCorrectness()
        {
            CheckObjectiveCalculation(times: 1);
        }

        [Fact]
        public void ObjectiveMultipleTimesCalculationCorrectness()
        {
            CheckObjectiveCalculation(times: 3);
        }

        [Fact]
        public void JacobianCalculationCorrectness()
        {
            CheckJacobianCalculation(times: 1);
        }

        [Fact]
        public void JacobianMultipleTimesCalculationCorrectness()
        {
            CheckJacobianCalculation(times: 3);
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
