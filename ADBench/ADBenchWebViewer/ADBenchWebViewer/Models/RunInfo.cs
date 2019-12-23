// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using Microsoft.Azure.Storage.Blob;

namespace ADBenchWebViewer.Models
{
    /// <summary>
    /// Representation of the information about a single run.
    /// </summary>
    public class RunInfo
    {
        /// <summary>
        /// Date when run is performed.
        /// </summary>
        public string Date { get; set; }

        /// <summary>
        /// Time when run is performed.
        /// </summary>
        public string Time { get; set; }

        /// <summary>
        /// Hash of the latest commit that repository has when run is performed.
        /// </summary>
        public string Commit { get; set; }

        /// <summary>
        /// Cloud blob directory contatins the run plots.
        /// </summary>
        public CloudBlobDirectory CloudBlobDirectory { get; set; }
    }
}
