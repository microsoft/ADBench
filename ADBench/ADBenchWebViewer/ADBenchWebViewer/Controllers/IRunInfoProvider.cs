// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using ADBenchWebViewer.Models;
using System.Collections.Generic;

namespace ADBenchWebViewer.Controllers
{
    /// <summary>
    /// Provides access to run info and run plots.
    /// </summary>
    public interface IRunInfoProvider
    {
        /// <summary>
        /// Returns info about runs that storage holds.
        /// </summary>
        /// <returns></returns>
        IDictionary<string, RunInfo> GetRunsInfo();

        /// <summary>
        /// Returns info about all files contain plots in this subdirectory.
        /// </summary>
        /// <param name="dir">Cloud root subdirectory files are searched in.</param>
        /// <returns>Dictionary whose keys are base subdirectory name.</returns>
        IDictionary<string, IEnumerable<PlotInfo>> GetPlotsInfo(string dirName);
    }
}
