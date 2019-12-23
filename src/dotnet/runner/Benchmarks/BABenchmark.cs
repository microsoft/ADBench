// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using DotnetRunner.Data;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace DotnetRunner.Benchmarks
{
    public class BABenchmark : Benchmark<BAInput, BAOutput>
    {
        protected override BAInput ReadInputData(string inputFilePath, DefaultParameters parameters)
        {
            return DataLoader.ReadBAInstance(inputFilePath);
        }

        protected override ITest<BAInput, BAOutput> GetTest(ModuleLoader moduleLoader)
        {
            return moduleLoader.GetBATest();
        }

        protected override void SaveOutputToFile(BAOutput output, string outputPrefix, string input_basename, string module_basename)
        {
            SavingOutput.SaveErrorsToFile(SavingOutput.ObjectiveFileName(outputPrefix, input_basename, module_basename), output.ReprojErr,
                                                                         output.WErr);
            SavingOutput.SaveSparseJToFile(SavingOutput.JacobianFileName(outputPrefix, input_basename, module_basename), output.J);
        }
    }
}
