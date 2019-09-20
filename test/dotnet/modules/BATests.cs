using DotnetRunner;
using DotnetRunner.Data;
using Xunit;

namespace DotnetTests
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
                Assert.Equal(-0.26904884923518940, output.ReprojErr[i], comparer);
                Assert.Equal(0.25994479267790188, output.ReprojErr[i + 1], comparer);
            }
            for (int i = 0; i < 10; i++)
            {
                Assert.Equal(0.82609265151599998, output.WErr[i], comparer);
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
            Assert.Equal(228.877, output.J.vals[0], comparer);
            Assert.Equal(634.575, output.J.vals[1], comparer);
            Assert.Equal(-782.223, output.J.vals[2], comparer);
            Assert.Equal(2.42893, output.J.vals[3], comparer);
            Assert.Equal(-11.7828, output.J.vals[4], comparer);
            Assert.Equal(2.54169, output.J.vals[5], comparer);
            Assert.Equal(-1.03657, output.J.vals[6], comparer);
            Assert.Equal(0.417022, output.J.vals[7], comparer);
            Assert.Equal(0.0, output.J.vals[8], comparer);
            Assert.Equal(-350.74, output.J.vals[9], comparer);
            Assert.Equal(-912.108, output.J.vals[10], comparer);
            Assert.Equal(-2.42893, output.J.vals[11], comparer);
            Assert.Equal(11.7828, output.J.vals[12], comparer);
            Assert.Equal(-0.834044, output.J.vals[307], comparer);
            Assert.Equal(-0.834044, output.J.vals[308], comparer);
            Assert.Equal(-0.834044, output.J.vals[309], comparer);
        }

        /*
        
        TEST_P(BaModuleTest, ObjectiveRunsMultipleTimes)
        {
            auto module = moduleLoader->get_ba_test();
            ASSERT_NE(module, nullptr);
            BAInput input;

            // Read instance
            read_ba_instance("batest.txt", input.n, input.m, input.p,
                input.cams, input.X, input.w, input.obs, input.feats);
            module->prepare(std::move(input));

            EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<BAInput, BAOutput>::calculate_objective));
        }

        TEST_P(BaModuleTest, JacobianRunsMultipleTimes)
        {
            auto module = moduleLoader->get_ba_test();
            ASSERT_NE(module, nullptr);
            BAInput input;

            // Read instance
            read_ba_instance("batest.txt", input.n, input.m, input.p,
                input.cams, input.X, input.w, input.obs, input.feats);
            module->prepare(std::move(input));

            EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<BAInput, BAOutput>::calculate_jacobian));
        }
                 */
    }
}
