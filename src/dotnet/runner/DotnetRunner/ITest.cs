using System;
using System.Collections.Generic;
using System.Text;

namespace DotnetRunner
{
    interface ITest<TInput, TOutput>
    {
        // This function must be called before any other function.
        void Prepare(TInput input);
        // calculate function
        void CalculateObjective(int times);
        void CalculateJacobian(int times);
        TOutput Output();
    }
}
