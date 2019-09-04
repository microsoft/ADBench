using System;

namespace DotnetRunner
{
    class Program
    {
        static int Main(string[] args)
        {
            if (args.Length < 8)
            {
                Console.Error.WriteLine("usage: DotnetRunner testType modulePath inputFilepath outputDir minimumMeasurableTime nrunsF nrunsJ timeLimit [-rep]");
                return 1;
            }

            var testType = args[0].ToUpperInvariant();
            var modulePath = args[1];
            var inputFilepath = args[2];
            var outputPrefix = args[3];
            var minimum_measurable_time = TimeSpan.FromMilliseconds(double.Parse(args[4]));
            var nruns_F = int.Parse(args[5]);
            var nruns_J = int.Parse(args[6]);
            var time_limit = TimeSpan.FromMilliseconds(double.Parse(args[7]));

            // read only 1 point and replicate it?
            var replicate_point = (args.Length > 8 && args[8] == "-rep");

            return 0;
        }
    }
}
