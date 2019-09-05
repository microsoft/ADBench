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
            assembly = Assembly.LoadFile(modulePath);
            var configuration = new ContainerConfiguration()
            .WithAssembly(assembly);
            container = configuration.CreateContainer();
        }

        public ITest<GMMInput, GMMOutput> GetGMMTest() => container.GetExport<ITest<GMMInput, GMMOutput>>();

        public ITest<BAInput, BAOutput> GetBATest() => container.GetExport<ITest<BAInput, BAOutput>>();

        public ITest<HandInput, HandOutput> GetHandTest() => container.GetExport<ITest<HandInput, HandOutput>>();

        public ITest<LSTMInput, LSTMOutput> GetLSTMTest() => container.GetExport<ITest<LSTMInput, LSTMOutput>>();

        ~ModuleLoader()
        {
            container.Dispose();
        }
    }
}