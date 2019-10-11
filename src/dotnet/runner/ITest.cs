using System;
using System.Collections.Generic;
using System.Text;

namespace DotnetRunner
{
    /// <summary>
    /// Automatic differentiation performance testing module for an objective
    /// corresponding to given Input and Output types. Differentiates the objective
    /// using some AD framework.
    /// </summary>
    public interface ITest<TInput, TOutput>
    {
        /// <summary>
        /// Converts the input data from the <typeparamref name="TInput"/> type
        /// in which it is provided by the calling benchmark runner into
        /// the format optimized for use with the tested AD framework.
        /// Stores it.
        /// 
        /// Optionally, performs other preparatory activities need by the tested AD framework.
        /// </summary>
        void Prepare(TInput input);
        /// <summary>
        /// Repeatedly computes the objective function <paramref name="times"/> times for the stored input.
        /// Stores results.
        /// </summary>
        void CalculateObjective(int times);
        /// <summary>
        /// Repeatedly computes the jacobian of the objective function <paramref name="times"/> times
        /// for the stored input. Stores results.
        /// </summary>
        void CalculateJacobian(int times);
        /// <summary>
        /// Converts the stored outputs to <typeparamref name="TOutput"/>.
        /// </summary>
        TOutput Output();
    }
}
