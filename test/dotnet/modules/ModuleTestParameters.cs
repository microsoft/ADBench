// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using System;
using System.Collections.Generic;
using System.Text;
using Xunit.Abstractions;

namespace DotnetModulesTests
{
    public struct ModuleTestParameters : IXunitSerializable
    {
        public string ModuleName { get; private set; }
        public double Tolerance { get; private set; }

        public ModuleTestParameters(string moduleName, double tolerance)
        {
            ModuleName = moduleName;
            Tolerance = tolerance;
        }

        public override string ToString()
        {
            return $"{ModuleName} (tolerance={Tolerance})";
        }

        public void Deserialize(IXunitSerializationInfo info)
        {
            ModuleName = info.GetValue<string>(nameof(ModuleName));
            Tolerance = info.GetValue<double>(nameof(Tolerance));
        }

        public void Serialize(IXunitSerializationInfo info)
        {
            info.AddValue(nameof(ModuleName), ModuleName);
            info.AddValue(nameof(Tolerance), Tolerance);
        }
    }
}
