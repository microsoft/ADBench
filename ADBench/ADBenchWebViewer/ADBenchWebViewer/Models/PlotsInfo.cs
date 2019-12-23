// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

namespace ADBenchWebViewer.Models
{
    /// <summary>
    /// Contatins information about single plot of the run.
    /// </summary>
    public class PlotInfo
    {
        /// <summary>
        /// Display name of the plot.
        /// </summary>
        public string DisplayName { get; set; }

        /// <summary>
        /// URL of the static version of the plot.
        /// </summary>
        public string StaticPlotUrl { get; set; }

        /// <summary>
        /// URL of the HTML file with plotly version of the plot.
        /// </summary>
        public string PlotlyPlotUrl { get; set; }
    }
}
