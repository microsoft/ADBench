using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace Microsoft.Research.AuDotNet
{
    /// <summary>
    /// An implementation of IConsole which simply writes to a TextWriter, 
    /// ignoring colour changes etc.
    /// </summary>
    public class TextWriterConsole : IConsole
    {
        TextWriter Out;
        public TextWriterConsole(TextWriter tw)
        {
            Out = tw;
        }

        public void Dispose()
        {
            Out.Dispose();
        }

        public void WriteLine(string msg)
        {
            Out.WriteLine(msg);
        }

        public void WriteLine(System.ConsoleColor fg, string msg)
        {
            WriteLine(msg);
        }
    }
}
