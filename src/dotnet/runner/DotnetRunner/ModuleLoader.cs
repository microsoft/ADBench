using DotnetRunner.Data;
using System.Composition;
using System.Composition.Hosting;
using System.IO;
using System.Reflection;

namespace DotnetRunner
{
    public class ModuleLoader
    {
        private Assembly assembly;
        /// <summary>
        /// 
        /// </summary>
        /// <param name="modulePath">Absolute path to the module assembly</param>
        public ModuleLoader(string modulePath)
        {
            assembly = Assembly.LoadFile(modulePath);
            var configuration = new ContainerConfiguration()
            .WithAssembly(assembly);

            using (var container = configuration.CreateContainer())
            {
                GMMTest = container.GetExport<ITest<GMMInput, GMMOutput>>();
                BATest = container.GetExport<ITest<BAInput, BAOutput>>();
                HandTest = container.GetExport<ITest<HandInput, HandOutput>>();
                LSTMTest = container.GetExport<ITest<LSTMInput, LSTMOutput>>();
            }
        }

        [Import]
        public ITest<GMMInput, GMMOutput> GMMTest { get; set; }

        [Import]
        public ITest<BAInput, BAOutput> BATest { get; set; }

        [Import]
        public ITest<HandInput, HandOutput> HandTest { get; set; }

        [Import]
        public ITest<LSTMInput, LSTMOutput> LSTMTest { get; set; }

    }
}