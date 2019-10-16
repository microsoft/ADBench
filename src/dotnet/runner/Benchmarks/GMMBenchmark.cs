using DotnetRunner.Data;

namespace DotnetRunner.Benchmarks
{
    public class GMMBenchmark : Benchmark<GMMInput, GMMOutput, GMMParameters>
    {
        protected override ITest<GMMInput, GMMOutput> GetTest(ModuleLoader moduleLoader) => moduleLoader.GetGMMTest();

        protected override GMMInput ReadInputData(string inputFilePath, GMMParameters parameters) => DataLoader.ReadGMMInstance(inputFilePath, parameters.ReplicatePoint);

        protected override void SaveOutputToFile(GMMOutput output, string outputPrefix, string input_basename, string module_basename)
        {
            SavingOutput.SaveValueToFile(SavingOutput.ObjectiveFileName(outputPrefix, input_basename, module_basename), output.Objective);
            SavingOutput.SaveVectorToFile(SavingOutput.JacobianFileName(outputPrefix, input_basename, module_basename), output.Gradient);
        }
    }
}
