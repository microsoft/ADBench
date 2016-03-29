using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace TestWPF
{
    /// <summary>
    /// DataContext for WpfUserControl, testing AuDotNet.DesignTime.GetSolutionDirectory()
    /// </summary>
    public class TestDataContext
    {
        public TestDataContext()
        {
        }

        public string ProjectDir
        {
            get { return Microsoft.Research.AuDotNet.DesignTime.GetSolutionDirectory(); }
        }
    }
}
