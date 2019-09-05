using DotnetRunner;
using DotnetRunner.Data;
using System;
using System.Composition;

namespace MockTest
{
    [Export(typeof(ITest<BAInput, BAOutput>))]
    public class BATest : ITest<BAInput, BAOutput>
    {
        public void Prepare(BAInput input)
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

        public BAOutput Output()
        {
            throw new NotImplementedException();
        }
    }
}
