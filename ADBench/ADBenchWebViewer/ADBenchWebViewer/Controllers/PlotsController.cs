using Microsoft.AspNetCore.Mvc;

namespace ADBenchWebViewer.Controllers
{
    public class PlotsController : Controller
    {
        private readonly IRunInfoProvider shareHelper;

        public PlotsController(IRunInfoProvider shareHandler) => this.shareHelper = shareHandler;

        public IActionResult Index()
        {
            var dirInfo = shareHelper.GetRunsInfo();
            return View(dirInfo);
        }

        public IActionResult GetStatic(string dir)
        {
            return View(shareHelper.GetPlotsInfo(dir));
        }

        public IActionResult GetPlotly(string dir)
        {
            return View(shareHelper.GetPlotsInfo(dir));
        }
    }
}