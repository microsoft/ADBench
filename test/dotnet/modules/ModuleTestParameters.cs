using System;
using System.Collections.Generic;
using System.Text;

namespace DotnetModulesTests
{
    public struct ModuleTestParameters
    {
        public string ModuleName { get; }
        public double Tolerance { get; }

        public ModuleTestParameters(string moduleName, double tolerance)
        {
            ModuleName = moduleName;
            Tolerance = tolerance;
        }
    }
}
