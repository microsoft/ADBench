// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using DotnetRunner.Data;

namespace DotnetRunner.Benchmarks
{
    public class LSTMBenchmark : Benchmark<LSTMInput, LSTMOutput>
    {
        protected override ITest<LSTMInput, LSTMOutput> GetTest(ModuleLoader moduleLoader) => moduleLoader.GetLSTMTest();

        protected override LSTMInput ReadInputData(string inputFilePath, DefaultParameters parameters) => DataLoader.ReadLSTMInstance(inputFilePath);

        protected override void SaveOutputToFile(LSTMOutput output, string outputPrefix, string input_basename, string module_basename)
        {
            SavingOutput.SaveValueToFile(SavingOutput.ObjectiveFileName(outputPrefix, input_basename, module_basename), output.Objective);
            SavingOutput.SaveVectorToFile(SavingOutput.JacobianFileName(outputPrefix, input_basename, module_basename), output.Gradient);
        }
    }
}
