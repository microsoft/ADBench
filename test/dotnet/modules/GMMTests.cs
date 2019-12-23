// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using DotnetRunner;
using DotnetRunner.Data;
using System.Collections.Generic;
using System.Linq;
using Xunit;

namespace DotnetModulesTests
{
    public class GMMTests
    {
        public static IEnumerable<object[]> TestParameterSet { get; } = new[]
        {
            new ModuleTestParameters("./DiffSharpModule.dll", 1e-10 )
        }.Select(m => new object[] { m }).ToArray();

        // helper methods
        void CheckObjectiveCalculation(string moduleName, double tolerance, int times)
        {
            using (var moduleLoader = new ModuleLoader(moduleName))
            {
                var module = moduleLoader.GetGMMTest();
                Assert.NotNull(module);
                var comparer = new TolerantDoubleComparer(tolerance);

                // Read instance
                var input = DataLoader.ReadGMMInstance("gmmtest.txt", false);

                module.Prepare(input);
                module.CalculateObjective(times);

                var output = module.Output();

                Assert.Equal(8.07380408004975791, output.Objective, comparer);
            }
        }

        void CheckJacobianCalculation(string moduleName, double tolerance, int times)
        {
            using (var moduleLoader = new ModuleLoader(moduleName))
            {
                var module = moduleLoader.GetGMMTest();
                Assert.NotNull(module);
                var comparer = new TolerantDoubleComparer(tolerance);

                // Read instance
                var input = DataLoader.ReadGMMInstance("gmmtest.txt", false);

                module.Prepare(input);
                module.CalculateJacobian(times);

                var output = module.Output();

                var correct_gradient = new[] { 1.08662855508652456e-01, -7.41270039523898472e-01, 6.32607184015246071e-01, 1.11692576532787013e+00, 1.63333013551455269e-01, -2.19989824071193142e-02, 2.27778292254236098e-01, 1.20963025612832187e+00, -6.06375920733956339e-02, 2.58529994051162237e+00, 1.12632694524213789e-01, 3.85744309849611777e-01, 7.35180573182305508e-02, 5.41836362715595232e+00, -3.21494409677446469e-01, 1.71892309775004937e+00, 8.60091090790866875e-01, -9.94640930466322848e-01 };

                Assert.Equal(correct_gradient, output.Gradient, comparer);
            }
        }

        [Theory]
        [MemberData(nameof(TestParameterSet))]
        public void Load(ModuleTestParameters testParameters)
        {
            using (var moduleLoader = new ModuleLoader(testParameters.ModuleName))
            {
                var test = moduleLoader.GetGMMTest();
                Assert.NotNull(test);
            }
        }

        [Theory]
        [MemberData(nameof(TestParameterSet))]
        public void ObjectiveCalculationCorrectness(ModuleTestParameters testParameters)
        {
            CheckObjectiveCalculation(testParameters.ModuleName, testParameters.Tolerance, times: 1);
        }

        [Theory]
        [MemberData(nameof(TestParameterSet))]
        public void ObjectiveMultipleTimesCalculationCorrectness(ModuleTestParameters testParameters)
        {
            CheckObjectiveCalculation(testParameters.ModuleName, testParameters.Tolerance, times: 3);
        }

        [Theory]
        [MemberData(nameof(TestParameterSet))]
        public void JacobianCalculationCorrectness(ModuleTestParameters testParameters)
        {
            CheckJacobianCalculation(testParameters.ModuleName, testParameters.Tolerance, times: 1);
        }

        [Theory]
        [MemberData(nameof(TestParameterSet))]
        public void JacobianMultipleTimesCalculationCorrectness(ModuleTestParameters testParameters)
        {
            CheckJacobianCalculation(testParameters.ModuleName, testParameters.Tolerance, times: 3);
        }

        [Theory]
        [MemberData(nameof(TestParameterSet))]
        public void ObjectiveRunsMultipleTimes(ModuleTestParameters testParameters)
        {
            using (var moduleLoader = new ModuleLoader(testParameters.ModuleName))
            {
                var module = moduleLoader.GetGMMTest();
                Assert.NotNull(module);

                // Read instance
                var input = DataLoader.ReadGMMInstance("gmmtest.txt", false);

                module.Prepare(input);

                Assert.True(Utils.CanObjectiveRunMultipleTimes(module.CalculateObjective));
            }
        }

        [Theory]
        [MemberData(nameof(TestParameterSet))]
        public void JacobianRunsMultipleTimes(ModuleTestParameters testParameters)
        {
            using (var moduleLoader = new ModuleLoader(testParameters.ModuleName))
            {
                var module = moduleLoader.GetGMMTest();
                Assert.NotNull(module);

                // Read instance
                var input = DataLoader.ReadGMMInstance("gmmtest.txt", false);

                module.Prepare(input);

                Assert.True(Utils.CanObjectiveRunMultipleTimes(module.CalculateJacobian));
            }
        }
    }
}
