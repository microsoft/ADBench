using System;
using System.Collections.Generic;
using System.Text;

namespace DotnetRunner.Data
{
    public struct BAInput
    {
        public int N { get; set; }
        public int M { get; set; }
        public int P { get; set; }

        public double[][] Cams { get; set; }
        public double[][] X { get; set; }
        public double[] W { get; set; }
        public double[][] Feats { get; set; }

        public int[][] Obs { get; set; }
    };

    public struct BAOutput
    {
        double[] ReprojErr { get; set; }
        double[] WErr { get; set; }

        //BASparseMat J;
    }
}
