using DotnetRunner.Data;

namespace DotnetRunner.Benchmarks
{
    public class HandBenchmark : Benchmark<HandInput, HandOutput, HandParameters>
    {
        protected override ITest<HandInput, HandOutput> GetTest(ModuleLoader moduleLoader) => moduleLoader.GetHandTest();

        protected override HandInput ReadInputData(string inputFilePath, HandParameters parameters) => DataLoader.ReadHandInstance(inputFilePath, parameters.IsComplicated);

        protected override void SaveOutputToFile(HandOutput output, string outputPrefix, string input_basename, string module_basename)
        {
            SavingOutput.SaveVectorToFile(SavingOutput.ObjectiveFileName(outputPrefix, input_basename, module_basename), output.Objective);
            SavingOutput.SaveMatrixToFile(SavingOutput.JacobianFileName(outputPrefix, input_basename, module_basename), output.Jacobian);
        }
    }
}
