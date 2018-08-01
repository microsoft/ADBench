using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Microsoft.Research.AuDotNet
{
    /// <summary>
    /// OK, so you know you shouldn't use System.Console.WriteLine in your 
    /// code, but it's so handy for little bits of debug output.  Well,
    /// use Au.Utils.WriteLine instead, and you get the following benefits:
    ///   (a) IConsole handles colour
    ///   (b) IConsole allows your clients to direct the outputs of different 
    ///       objects to different places.
    /// To do (b), just use Au.Utils.PushConsole and Au.Utils.PopConsole to 
    /// change where output goes.
    /// 
    /// Of course, you could use System.Console having set Console.SetOut,
    /// but it's much more limited.
    /// 
    /// </summary>
    public interface IConsole: IDisposable
    {
        /// <summary>
        /// Write a line to the IConsole
        /// </summary>
        /// <param name="msg">The line to be written</param>
        void WriteLine(string msg);

        /// <summary>
        /// Write a line to the IConsole colourfully.
        /// </summary>
        /// <param name="fg">Foreground colour of line to be written</param>
        /// <param name="msg">The line to be written</param>
        void WriteLine(System.ConsoleColor fg, string msg);
    }
}
