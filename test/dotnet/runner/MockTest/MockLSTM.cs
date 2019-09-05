using DotnetRunner;
using DotnetRunner.Data;
using System;
using System.Composition;

namespace MockTest
{
    [Export(typeof(ITest<LSTMInput, LSTMOutput>))]
    public class MockLSTM : ITest<LSTMInput, LSTMOutput>
    {
        public void Prepare(LSTMInput input)
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

        public LSTMOutput Output()
        {
            throw new NotImplementedException();
        }
    }
}
