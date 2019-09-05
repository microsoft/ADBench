using DotnetRunner.Data;
using System;
using System.Reflection;

namespace DotnetRunner
{
    public class ModuleLoader
    {
        private Assembly assembly;
        public ModuleLoader(string modulePath)
        {
            assembly = Assembly.LoadFile(modulePath);
        }

        public ITest<GMMInput, GMMOutput> GetGMMTest()
        {
            throw new NotImplementedException();
        }

        public ITest<BAInput, BAOutput> GetBATest()
        {
            throw new NotImplementedException();
        }

        public ITest<HandInput, HandOutput> GetHandTest()
        {
            throw new NotImplementedException();
        }

        public ITest<LSTMInput, LSTMOutput> GetLSTMTest()
        {
            throw new NotImplementedException();
        }


    }
}