// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using Microsoft.AspNetCore.Mvc;

namespace ADBenchWebViewer.Controllers
{
    public class PlotsController : Controller
    {
        private readonly IRunInfoProvider runInfoProvider;

        public PlotsController(IRunInfoProvider runInfoProvider) => this.runInfoProvider = runInfoProvider;

        public IActionResult Index()
        {
            var dirInfo = runInfoProvider.GetRunsInfo();
            return View(dirInfo);
        }

        public IActionResult GetStatic(string dir)
        {
            return View(runInfoProvider.GetPlotsInfo(dir));
        }

        public IActionResult GetPlotly(string dir)
        {
            return View(runInfoProvider.GetPlotsInfo(dir));
        }
    }
}