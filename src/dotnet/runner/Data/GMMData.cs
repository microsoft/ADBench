using System;
using System.Collections.Generic;
using System.Text;

namespace DotnetRunner.Data
{
    public struct Wishart
    {
        double Gamma { get; set; }
        int M { get; set; }
    }


    public struct GMMInput
    {
        int D { get; set; }
        int K { get; set; }
        int N { get; set; }

        double[] Alphas { get; set; }
        double[] Means { get; set; }
        double[] Icf { get; set; }
        double[] X { get; set; }

        Wishart Wishart { get; set; }
    }

    public struct GMMOutput
    {
        double Objective { get; set; }
        double[] Gradient { get; set; }
    }

    public struct GMMParameters
    {
        bool ReplicatePoint { get; set; }
    }
}
