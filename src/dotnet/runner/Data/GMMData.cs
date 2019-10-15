using System;
using System.Collections.Generic;
using System.Text;

namespace DotnetRunner.Data
{
    public struct Wishart
    {
        public double Gamma { get; set; }
        public int M { get; set; }
    }


    public struct GMMInput
    {
        public int D { get; set; }
        public int K { get; set; }
        public int N { get; set; }

        public double[] Alphas { get; set; }
        public double[][] Means { get; set; }
        public double[][] Icf { get; set; }
        public double[][] X { get; set; }

        public Wishart Wishart { get; set; }
    }

    public struct GMMOutput
    {
        public double Objective { get; set; }
        public double[] Gradient { get; set; }
    }

    public struct GMMParameters
    {
        public bool ReplicatePoint { get; set; }
    }
}
