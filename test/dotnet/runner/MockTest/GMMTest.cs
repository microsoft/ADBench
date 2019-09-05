using DotnetRunner;
using DotnetRunner.Data;
using System;
using System.Composition;

namespace MockTest
{
    [Export(typeof(ITest<GMMInput, GMMOutput>))]
    public class GMMTest : ITest<GMMInput, GMMOutput>
    {
        public void Prepare(GMMInput input)
        {
            throw new NotImplementedException();
        }

        public void CalculateJacobian(int times)
        {
            throw new NotImplementedException();
        }

        public void CalculateObjective(int times)
        {
            throw new NotImplementedException();
        }

        public GMMOutput Output()
        {
            throw new NotImplementedException();
        }
    }
}
