using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace JacobianComparisonLib
{
    public class JacobianComparison
    {
        public double AllowedAbsDifference { get; protected set; }
        public double AllowedRelDifference { get; protected set; }

        public string File1 { get; protected set; } = "";
        public string File2 { get; protected set; } = "";

        public bool DimensionMismatch { get; protected set; } = false;
        public bool ParseError { get; protected set; } = false;
        public double MaxAbsDifference { get; protected set; } = 0.0;
        public double MaxRelDifference { get; protected set; } = 0.0;
        public double AvgAbsDifference { get; protected set; } = 0.0;
        public double AvgRelDifference { get; protected set; } = 0.0;
        public int AbsDifferenceViolationCount { get; protected set; } = 0;
        public int RelDifferenceViolationCount { get; protected set; } = 0;
        public int NumberComparisonCount { get; protected set; } = 0;
        public List<(int, int)> AbsDifferenceViolations { get; protected set; } = new List<(int, int)>();
        public List<(int, int)> RelDifferenceViolations { get; protected set; } = new List<(int, int)>();
        public string Error { get; protected set; } = "";

        public JacobianComparison(double allowedAbsDifference, double allowedRelDifference)
        {
            this.AllowedAbsDifference = allowedAbsDifference;
            this.AllowedRelDifference = allowedRelDifference;
        }
    
        public void CompareNumbers(double x, double y, int posX, int posY)
        {
            double absdiff = Math.Abs(x - y);
            double reldiff = absdiff / Math.Max(Math.Abs(x), Math.Abs(y));
            if (absdiff > this.AllowedAbsDifference)
            {
                this.AbsDifferenceViolationCount++;
                this.AbsDifferenceViolations.Add((posX, posY));
            }
            if (reldiff > this.AllowedRelDifference)
            {
                this.RelDifferenceViolationCount++;
                this.RelDifferenceViolations.Add((posX, posY));
            }
            if (absdiff > this.MaxAbsDifference)
            {
                this.MaxAbsDifference = absdiff;
            }
            if (reldiff > this.MaxRelDifference)
            {
                this.MaxRelDifference = reldiff;
            }
            ++this.NumberComparisonCount;
            double compCount = (double)this.NumberComparisonCount;
            double a = (compCount - 1.0) / compCount;
            double b = 1.0 / compCount;
            this.AvgAbsDifference = a * this.AvgAbsDifference + b * absdiff;
            this.AvgRelDifference = a * this.AvgRelDifference + b * reldiff;
        }
    
        public void CompareNumLines(double[] line1, double[] line2, int posY)
        {
            if (line1.Length != line2.Length)
            {
                this.DimensionMismatch = true;
                this.Error = "Dimension mismatch on line posY";
                return;
            }
            for (int n = 0; n < line1.Length; ++n)
            {
                this.CompareNumbers(line1[n], line2[n], n, posY);
            }
        }
    
        public void CompareJaggedArrayFiles(string path1, string path2)
        {
            this.File1 = path1;
            this.File2 = path2;
            if (TryParseJaggedArrayFile(path1, out double[][] j1)
                && TryParseJaggedArrayFile(path2, out double[][] j2))
            {
                if (j1.Length != j2.Length)
                {
                    this.DimensionMismatch = true;
                    this.Error = "Texts have different numbers of lines";
                    return;
                }
                for (int n = 0; n < j1.Length; ++n)
                {
                    this.CompareNumLines(j1[n], j2[n], n);
                }
            }
        }

        public void CompareVectorFiles(string path1, string path2)
        {
            this.File1 = path1;
            this.File2 = path2;
            if (TryParseVectorFile(path1, out double[] j1)
                && TryParseVectorFile(path2, out double[] j2))
            {
                if (j1.Length != j2.Length)
                {
                    this.DimensionMismatch = true;
                    this.Error = "Texts have different numbers of lines";
                    return;
                }
                for (int n = 0; n < j1.Length; ++n)
                {
                    this.CompareNumbers(j1[n], j2[n], 0, n);
                }
            }
        }

        public void CompareGmmFullAndPartGradients(string path1, string[] paths2)
        {
            this.File1 = path1;
            this.File2 = string.Join("; ", paths2);
            if (TryParseVectorFile(path1, out double[] j1)
                && TryParseIntVectorFile(paths2[0], out int[] positions)
                && TryParseVectorFile(paths2[1], out double[] alphas)
                && TryParseVectorFile(paths2[2], out double[] means)
                && TryParseVectorFile(paths2[3], out double[] icfs))
            {
                double[][] parts = new double[][] { alphas, means, icfs };
                for (int i = 0; i < 3; i++)
                {
                    int shift = positions[i];
                    for (int n = 0; n < parts[i].Length; ++n)
                    {
                        this.CompareNumbers(j1[shift + n], parts[i][n], 0, shift + n);
                    }
                }
            }
        }

        public bool ViolationsHappened()
        {
            return this.ParseError || this.DimensionMismatch || (this.AbsDifferenceViolationCount + this.RelDifferenceViolationCount) > 0;
        }

        public static string TabSeparatedHeader => "File 1\tFile 2\tAllowed Absolute Difference\tAllowed Relative Difference\tDimension Mismatch\tParse Error\tMax Absolute Difference\tMax Relative Difference\tAverage Absolute Difference\tAverage Relative Difference\tAbsolute Difference Violation Count\tRelative Difference Violation Count\tNumber Comparison Count\tAbsolute Difference Violations (1st 10)\tRelative Difference Violations (1st 10)\tError Message";

        public string ToTabSeparatedString()
        {
            return $"{this.File1}\t{this.File2}\t{this.AllowedAbsDifference}\t{this.AllowedRelDifference}\t{this.DimensionMismatch}\t{this.ParseError}\t{this.MaxAbsDifference}\t{this.MaxRelDifference}\t{this.AvgAbsDifference}\t{this.AvgRelDifference}\t{this.AbsDifferenceViolationCount}\t{this.RelDifferenceViolationCount}\t{this.NumberComparisonCount}\t{string.Join(" ", this.AbsDifferenceViolations.Take(10))}\t{string.Join(" ", this.RelDifferenceViolations.Take(10))}\t{this.Error}";
        }

        private bool TryParseVectorFile(string path, out double[] result)
        {
            List<double> acc = new List<double>();
            int curLine = 0;
            foreach (string line in File.ReadLines(path).Where(s => !string.IsNullOrWhiteSpace(s)))
            {
                if (double.TryParse(line, out double d) && !double.IsNaN(d))
                {
                    acc.Add(d);
                }
                else
                {
                    this.ParseError = true;
                    this.Error = $"Failed to parse file {path} - line {line} index {curLine}.";
                    result = null;
                    return false;
                }
                ++curLine;
            }
            result = acc.ToArray();
            return true;
        }

        private bool TryParseIntVectorFile(string path, out int[] result)
        {
            List<int> acc = new List<int>();
            int curLine = 0;
            foreach (string line in File.ReadLines(path).Where(s => !string.IsNullOrWhiteSpace(s)))
            {
                if (int.TryParse(line, out int n))
                {
                    acc.Add(n);
                }
                else
                {
                    this.ParseError = true;
                    this.Error = $"Failed to parse file {path} - line {line} index {curLine}.";
                    result = null;
                    return false;
                }
                ++curLine;
            }
            result = acc.ToArray();
            return true;
        }

        private bool TryParseJaggedArrayFile(string path, out double[][] result)
        {
            List<double[]> fileAcc = new List<double[]>();
            int curLine = 0;
            foreach (string line in File.ReadLines(path))
            {
                string[] parts = line.Split(' ', '\t');
                List<double> lineAcc = new List<double>(parts.Length);
                int curPos = 0;
                foreach (string elem in parts.Where(s => !string.IsNullOrWhiteSpace(s)))
                {
                    if (double.TryParse(elem, out double d) && !double.IsNaN(d))
                    {
                        lineAcc.Add(d);
                    }
                    else
                    {
                        this.ParseError = true;
                        this.Error = $"Failed to parse file {path} - line {curLine} - element {elem} with index {curPos}.";
                        result = null;
                        return false;
                    }
                    ++curPos;
                }
                if (lineAcc.Count > 0)
                    fileAcc.Add(lineAcc.ToArray());
                ++curLine;
            }
            result = fileAcc.ToArray();
            return true;
        }
    }
}
