using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Microsoft.Research.AuDotNet
{
    /// <summary>
    /// An implementation of IConsole which writes to the system console
    /// </summary>
    public class ConsoleConsole : IConsole
    {
        public void WriteLine(string msg)
        {
            Console.WriteLine(msg);
        }

        public void Dispose()
        {
        }

        public void WriteLine(System.ConsoleColor fg, string msg)
        {
            ConsoleColor c = Console.ForegroundColor;
            Console.ForegroundColor = fg;
            Console.WriteLine(msg);
            Console.ForegroundColor = c;
        }
    }
}
