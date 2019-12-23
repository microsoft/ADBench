// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using System;
using System.Collections.Generic;
using System.Linq;
using ADBenchWebViewer.Models;
using Microsoft.Azure.Storage.Blob;

namespace ADBenchWebViewer.Controllers
{
    /// <summary>
    /// Contains helping methods for working with Azure Blob.
    /// </summary>
    public class AzureBlobHelper : IRunInfoProvider
    {
        private const string staticSubdirName = "static";
        private const string plotlySubdirName = "plotly";

        private readonly CloudBlobContainer rootContatiner;

        public AzureBlobHelper(string containerAddress)
        {
            var containerUri = new Uri(containerAddress);
            rootContatiner = new CloudBlobContainer(containerUri);
        }

        public IDictionary<string, RunInfo> GetRunsInfo()
        {
            return rootContatiner.ListBlobs()
                .Where(item => item is CloudBlobDirectory)
                .Select(item => item as CloudBlobDirectory)
                .OrderByDescending(dir => dir.Prefix)
                .ToDictionary(
                    dir => dir.Prefix,
                    dir =>
                    {
                        var parts = dir.Prefix.Trim('/').Split('_');
                        return new RunInfo()
                        {
                            Date = parts[0].Replace('-', '.'),
                            Time = parts[1].Replace('-', ':'),
                            Commit = parts[2],
                            CloudBlobDirectory = dir
                        };
                    }
                );
        }

        public IDictionary<string, IEnumerable<PlotInfo>> GetPlotsInfo(string dirName)
        {
            var cloudDirectory = GetRunsInfo()[dirName].CloudBlobDirectory;
            var staticPlotDir = cloudDirectory.GetDirectoryReference(staticSubdirName);
            var plotlyPlotDir = cloudDirectory.GetDirectoryReference(plotlySubdirName);

            var staticPlots = GetPlotBlobs(staticPlotDir);
            var plotlyPlots = GetPlotBlobs(plotlyPlotDir);

            return staticPlots
                .Zip(plotlyPlots, (first, second) => (first.Key, val: (staticPlots: first.Value, plotlyPlots: second.Value)))
                .ToDictionary(
                    item => CapitalFirstLetter(item.Key),
                    item => item.val.staticPlots
                        .Zip(
                            item.val.plotlyPlots,
                            (st, pl) => new PlotInfo()
                            {
                                DisplayName = GetDisplayName(pl.Name),
                                StaticPlotUrl = st.Uri.ToString(),
                                PlotlyPlotUrl = pl.Uri.ToString()
                            }
                        )
                );

            IDictionary<string, IEnumerable<CloudBlob>> GetPlotBlobs(CloudBlobDirectory cloudDir) =>
                cloudDir.ListBlobs()
                    .Where(item => item is CloudBlobDirectory)
                    .Select(item => item as CloudBlobDirectory)
                    .Select(dir => (name: dir.Prefix.Trim('/').Split('/').Last(), directory: dir))
                    .OrderBy(pair => pair.name)
                    .ToDictionary(
                        pair => pair.name,
                        pair => pair.directory.ListBlobs()
                            .Where(item => item is CloudBlob)
                            .Select(item => item as CloudBlob)
                    );

            string GetDisplayName(string name) => System.IO.Path.GetFileNameWithoutExtension(name.Split('/').Last());

            string CapitalFirstLetter(string str) => char.ToUpper(str[0]) + str.Substring(1);
        }
    }
}
