using System;
using System.Collections.Generic;
using System.Text;

namespace DotnetRunner.Data
{
    public struct Wishart
    {
        double gamma { get; set; }
        int m { get; set; }
    }


    public struct GMMInput
    {
        int d { get; set; }
        int k { get; set; }
        int n { get; set; }

        double[] alphas { get; set; }
        double[] means { get; set; }
        double[] icf { get; set; }
        double[] x { get; set; }

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
