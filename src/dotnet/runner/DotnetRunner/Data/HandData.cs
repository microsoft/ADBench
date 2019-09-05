using System;
using System.Collections.Generic;
using System.Text;

namespace DotnetRunner.Data
{
    public struct HandInput
    {
        double[] Theta { get; set; }
        //HandDataLightMatrix data;
        double[] Us { get; set; }
    };

    public struct HandOutput
    {
        double[] Objective { get; set; }
        int JacobianNCols { get; set; }
        int JacobianNRows { get; set; }
        double[] Jacobian { get; set; }
    };

    public struct HandParameters
    {
        bool IsComplicated { get; set; }
    };
}
