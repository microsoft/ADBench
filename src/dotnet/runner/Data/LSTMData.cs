using System;
using System.Collections.Generic;
using System.Text;

namespace DotnetRunner.Data
{
    public struct LSTMInput
    {
        public int LayerCount { get; set; }
        public int CharCount { get; set; }
        public int CharBits { get; set; }
        public double[][] MainParams { get; set; }
        public double[][] ExtraParams { get; set; }
        public double[][] State { get; set; }
        public double[][] Sequence { get; set; }
    };

    public struct LSTMOutput
    {
        public double Objective { get; set; }
        public double[] Gradient { get; set; }
    };
}
