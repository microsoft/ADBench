using DotnetRunner.Data;
using System.Composition;
using System.Composition.Hosting;
using System.Reflection;

namespace DotnetRunner
{
    public class ModuleLoader
    {
        private Assembly assembly;
        private CompositionHost container;
        /// <summary>
        /// 
        /// </summary>
        /// <param name="modulePath">Absolute path to the module assembly</param>
        public ModuleLoader(string modulePath)
        {
            assembly = Assembly.LoadFrom(modulePath);
            var configuration = new ContainerConfiguration()
            .WithAssembly(assembly);
            container = configuration.CreateContainer();
        }

        public ITest<GMMInput, GMMOutput> GetGMMTest()
        {
            if (container.TryGetExport(out ITest<GMMInput, GMMOutput> gmmTest))
                return gmmTest;
            else
                throw new System.Exception("The specified module doesn't support the GMM objective.");
        }

        public ITest<BAInput, BAOutput> GetBATest()
        {
            if (container.TryGetExport(out ITest<BAInput, BAOutput> baTest))
                return baTest;
            else
                throw new System.Exception("The specified module doesn't support the BA objective.");
        }

        public ITest<HandInput, HandOutput> GetHandTest()
        {
            if (container.TryGetExport(out ITest<HandInput, HandOutput> handTest))
                return handTest;
            else
                throw new System.Exception("The specified module doesn't support the Hand objective.");
        }

        public ITest<LSTMInput, LSTMOutput> GetLSTMTest()
        {
            if (container.TryGetExport(out ITest<LSTMInput, LSTMOutput> lstmTest))
                return lstmTest;
            else
                throw new System.Exception("The specified module doesn't support the LSTM objective.");
        }

        ~ModuleLoader()
        {
            container.Dispose();
        }
    }
}