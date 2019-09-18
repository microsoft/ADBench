using System;
using System.Collections.Generic;
using System.Text;

namespace DotnetRunner.Data
{
    public struct LSTMInput
    {
        int L { get; set; }
        int C { get; set; }
        int B { get; set; }
        double[] MainParams { get; set; }
        double[] ExtraParams { get; set; }
        double[] State { get; set; }
        double[] Sequence { get; set; }
    };

    public struct LSTMOutput
    {
        double Objective { get; set; }
        double[] Gradient { get; set; }
    };
}
