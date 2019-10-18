using System;
using System.Collections.Generic;
using System.Text;

namespace DotnetRunner.Data
{
    public struct HandModel
    {
        public string[] BoneNames { get; set; }
        public int[] Parents { get; set; }
        public double[][,] BaseRelatives { get; set; }
        public double[][,] InverseBaseAbsolutes { get; set; }
        public double[,] BasePositions { get; set; }
        public double[][] Weights { get; set; }
        public int[][] Triangles { get; set; }
        public bool IsMirrored { get; set; }
    }
    public struct HandInput
    {
        public HandModel Model { get; set; }
        public int[] Correspondences { get; set; }
        /// <summary>
        /// double[point count][3]
        /// </summary>
        public double[][] Points { get; set; }
        public double[] Theta { get; set; }
        /// <summary>
        /// double[point count][2]
        /// Is present only for 'complicated' kind of problems.
        /// </summary>
        public double[][] Us { get; set; }
    };

    public struct HandOutput
    {
        public double[] Objective { get; set; }
        public double[][] Jacobian { get; set; }
    };

    public struct HandParameters
    {
        public bool IsComplicated { get; set; }
    };
}
