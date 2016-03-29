using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using EnvDTE;

namespace Microsoft.Research.AuDotNet
{
    /// <summary>
    /// A collection of utilities for use at Design time in the Visual Studio XAML editor.  
    /// Specifically, DesignTime.GetSolutionDirectory() can be used to point design-time objects to data in the solution.
    /// </summary>
    public class DesignTime
    {
        [DllImport("ole32.dll")]
        public static extern int GetRunningObjectTable(int reserved, out IRunningObjectTable prot);

        [DllImport("ole32.dll")]
        public static extern int CreateBindCtx(int reserved, out IBindCtx ppbc);

        /// <summary>
        /// Search Running Object Table for a given process
        /// </summary>
        /// <param name="processId">The ID of the process for which to search</param>
        /// <param name="instance">The returned _DTE object</param>
        /// <returns>True if a matching _DTE object was found</returns>
        public static bool GetVSInstance(int processId, out _DTE instance)
        {
            IRunningObjectTable runningObjectTable;
            GetRunningObjectTable(0, out runningObjectTable);
            
            IEnumMoniker monikerEnumerator;
            runningObjectTable.EnumRunning(out monikerEnumerator);
            monikerEnumerator.Reset();

            IMoniker[] monikers = new IMoniker[1];
            IntPtr numFetched = IntPtr.Zero;
            while (monikerEnumerator.Next(1, monikers, numFetched) == 0)
            {
                IBindCtx ctx;
                CreateBindCtx(0, out ctx);

                string runningObjectName;
                monikers[0].GetDisplayName(ctx, null, out runningObjectName);
                if (runningObjectName.StartsWith("!VisualStudio"))
                {
                    object runningObjectVal;
                    runningObjectTable.GetObject(monikers[0], out runningObjectVal);

                    if (runningObjectVal is _DTE)
                    {
                        int currentProcessId = int.Parse(runningObjectName.Split(':')[1]);

                        if (currentProcessId == processId)
                        {
                            instance = (_DTE)runningObjectVal;
                            return true;
                        }
                    }
                }
            }

            instance = null;
            return false;
        }

        /// <summary>
        /// Search Running Object Table for a running VisualStudio instance which has open a particular solution.
        /// Typical usage might be EnvDTE.Solution sln = DesignTime.GetVisualStudioInstanceBySolution(@"\\My Solution\.sln$")
        /// </summary>
        /// <param name="solution_file_regex">Regular expression matching the solution fullname</param>
        /// <returns>The Solution object if a match was found, null otherwise</returns>
        public static EnvDTE.Solution GetVisualStudioInstanceBySolution(string solution_file_regex)
        {
            System.Text.RegularExpressions.Regex re = new System.Text.RegularExpressions.Regex(solution_file_regex);

            IRunningObjectTable runningObjectTable;
            GetRunningObjectTable(0, out runningObjectTable);

            IEnumMoniker monikerEnumerator;
            runningObjectTable.EnumRunning(out monikerEnumerator);
            monikerEnumerator.Reset();

            IMoniker[] monikers = new IMoniker[1];
            IntPtr numFetched = IntPtr.Zero;
            while (monikerEnumerator.Next(1, monikers, numFetched) == 0)
            {
                IBindCtx ctx;
                CreateBindCtx(0, out ctx);

                string runningObjectName;
                monikers[0].GetDisplayName(ctx, null, out runningObjectName);
                if (re.IsMatch(runningObjectName))
                {
                    object runningObjectVal;
                    runningObjectTable.GetObject(monikers[0], out runningObjectVal);
                    EnvDTE.Solution sln = runningObjectVal as EnvDTE.Solution;
                    if (sln != null)
                        return sln;
                }
            }

            return null;
        }

        public static string GetSolutionDirectory()
        {
            // Get an instance of the currently running Visual Studio .NET IDE.
            
            // We don't do this:
            //    EnvDTE.DTE dte = (EnvDTE.DTE)System.Runtime.InteropServices.Marshal.GetActiveObject("VisualStudio.DTE");
            // because with multiple Visual Studio instances running, it will return an arbitrary one.

            EnvDTE._DTE dte;

            int nProcessID = System.Diagnostics.Process.GetCurrentProcess().Id;
            if (GetVSInstance(nProcessID, out dte))
            {
                string s = dte.Solution.FullName;
                //foreach (var sln in dte.ActiveSolutionProjects)
                //    s += "|>" + (sln as EnvDTE.Project).FullName;
                return "inVS: " + System.IO.Path.GetDirectoryName(s);
            }
            // This must be called from a Visual Studio process
            return "<Not in Visual Studio " + nProcessID + ">";
        }
    }
}
