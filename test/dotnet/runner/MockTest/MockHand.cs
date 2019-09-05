using DotnetRunner;
using DotnetRunner.Data;
using System;
using System.Composition;

namespace MockTest
{
    [Export(typeof(ITest<HandInput, HandOutput>))]
    public class MockHand : ITest<HandInput, HandOutput>
    {
        public void Prepare(HandInput input)
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

        public HandOutput Output()
        {
            throw new NotImplementedException();
        }
    }
}
