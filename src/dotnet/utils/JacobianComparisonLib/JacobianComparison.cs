using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace JacobianComparisonLib
{
    public class JacobianComparison
    {
        public double Tolerance { get; protected set; }

        public string File1 { get; protected set; } = "";
        public string File2 { get; protected set; } = "";

        public bool DimensionMismatch { get; protected set; } = false;
        public bool ParseError { get; protected set; } = false;
        public double MaxDifference { get; protected set; } = 0.0;
        public double AvgDifference { get; protected set; } = 0.0;
        public int DifferenceViolationCount { get; protected set; } = 0;
        public int NumberComparisonCount { get; protected set; } = 0;
        public List<(int, int)> DifferenceViolations { get; protected set; } = new List<(int, int)>();
        public string Error { get; protected set; } = "";

        public JacobianComparison(double tolerance)
        {
            this.Tolerance = tolerance;
        }

        public static double Difference(double x, double y)
        {
            if (x == y)
                return 0.0;
            
            double absX = Math.Abs(x);
            double absY = Math.Abs(y);
            double absdiff = Math.Abs(x - y);
            double normCoef = Math.Min(absX + absY, double.MaxValue);
            return normCoef > 1.0 ? absdiff / normCoef : absdiff;
        }
    
        public void CompareNumbers(double x, double y, int posX, int posY)
        {
            double diff = Difference(x, y);
            if (!(diff <= this.Tolerance))
            {
                this.DifferenceViolationCount++;
                this.DifferenceViolations.Add((posX, posY));
            }
            this.MaxDifference = Math.Max(this.MaxDifference, diff);
            ++this.NumberComparisonCount;
            double compCount = (double)this.NumberComparisonCount;
            double a = (compCount - 1.0) / compCount;
            double b = 1.0 / compCount;
            this.AvgDifference = a * this.AvgDifference + b * diff;
        }

        public void CompareGmmFullAndPartGradients(string path1, string[] paths2)
        {
            this.File1 = path1;
            this.File2 = string.Join("; ", paths2);

            if (!File.Exists(path1))
            {
                this.ParseError = true;
                this.Error = $"File {path1.Replace("\\", "/")} doesn't exist.";
                return;
            }
            foreach (var path2 in paths2)
            {
                if (!File.Exists(path2))
                {
                    this.ParseError = true;
                    this.Error = $"File {path2.Replace("\\", "/")} doesn't exist.";
                    return;
                }
            }

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
                        if (shift + n >= j1.Length)
                        {
                            this.DimensionMismatch = true;
                            this.Error = $"Dimension mismatch";
                            return;
                        }
                        this.CompareNumbers(j1[shift + n], parts[i][n], 0, shift + n);
                    }
                }
            }
        }

        public void CompareFiles(string path1, string path2)
        {
            this.File1 = path1;
            this.File2 = path2;
            int posX = 0, posY = 0;

            if (!File.Exists(path1))
            {
                this.ParseError = true;
                this.Error = $"File {path1.Replace("\\", "/")} doesn't exist.";
                return;
            }

            if (!File.Exists(path2))
            {
                this.ParseError = true;
                this.Error = $"File {path2.Replace("\\", "/")} doesn't exist.";
                return;
            }

            using (var tokenEnumerator1 = ParseFile(path1).GetEnumerator())
            using (var tokenEnumerator2 = ParseFile(path2).GetEnumerator())
            {
                while (tokenEnumerator1.MoveNext() && tokenEnumerator2.MoveNext())
                {
                    if (tokenEnumerator1.Current.Kind == TokenKind.Error || tokenEnumerator2.Current.Kind == TokenKind.Error)
                        return;
                    if (tokenEnumerator1.Current.Kind != tokenEnumerator2.Current.Kind)
                    {
                        this.DimensionMismatch = true;
                        this.Error = $"Dimension mismatch at ({posX}, {posY})";
                        return;
                    }
                    if (tokenEnumerator1.Current.Kind == TokenKind.Number)
                    {
                        CompareNumbers(tokenEnumerator1.Current.Value, tokenEnumerator2.Current.Value, posX, posY);
                        ++posX;
                    }
                    else
                    {
                        ++posY;
                        posX = 0;
                    }
                }
                if (tokenEnumerator1.MoveNext() || tokenEnumerator2.MoveNext())
                {
                    this.DimensionMismatch = true;
                    this.Error = $"Dimension mismatch at ({posX}, {posY})";
                }
            }
        }

        public bool ViolationsHappened()
        {
            return this.ParseError || this.DimensionMismatch || this.DifferenceViolationCount > 0;
        }

        public static string TabSeparatedHeader => "File 1\tFile 2\tTolerance\tDimension Mismatch\tParse Error\tMax Difference\tAverage Difference\tDifference Violation Count\tNumber Comparison Count\tDifference Violations (1st 10)\tError Message";

        public string ToTabSeparatedString()
        {
            return $"{this.File1}\t{this.File2}\t{this.Tolerance}\t{this.DimensionMismatch}\t{this.ParseError}\t{this.MaxDifference}\t{this.AvgDifference}\t{this.DifferenceViolationCount}\t{this.NumberComparisonCount}\t{string.Join(" ", this.DifferenceViolations.Take(10))}\t{this.Error}";
        }

        public string ToJsonString()
        {
            return $@"{{
    ""{nameof(Tolerance)}"": {this.Tolerance},
    ""{nameof(File1)}"": ""{this.File1.Replace("\\", "/")}"",
    ""{nameof(File2)}"": ""{this.File2.Replace("\\", "/")}"",
    ""{nameof(DimensionMismatch)}"": {this.DimensionMismatch.ToString().ToLower()},
    ""{nameof(ParseError)}"": {this.ParseError.ToString().ToLower()},
    ""{nameof(MaxDifference)}"": {this.MaxDifference},
    ""{nameof(AvgDifference)}"": {this.AvgDifference},
    ""{nameof(DifferenceViolationCount)}"": {this.DifferenceViolationCount},
    ""{nameof(NumberComparisonCount)}"": {this.NumberComparisonCount},
    ""{nameof(Error)}"": ""{this.Error}"",
    ""ViolationsHappened"": {this.ViolationsHappened().ToString().ToLower()}
}}";
        }

        private enum TokenKind
        {
            Number,
            NewLine,
            Error
        }

        private struct Token
        {
            public TokenKind Kind;
            public double Value;

            public static Token CreateNewLine() => new Token { Kind = TokenKind.NewLine };
            public static Token CreateDouble(double value) => new Token { Kind = TokenKind.Number, Value = value };
            public static Token CreateError() => new Token { Kind = TokenKind.Error };
        }

        private IEnumerable<Token> ParseFile(string path)
        {
            int curLine = 0, curPos = 0, lastNumStartPos = 0;
            StringBuilder acc = new StringBuilder(32);
            char c;
            bool foundNewLine = false;
            using (var reader = File.OpenText(path))
            {
                // Skipping whitespace in the beginning
                while (reader.Peek() >= 0 && char.IsWhiteSpace((char)reader.Peek()))
                {
                    c = (char)reader.Read();
                    if (c == '\n')
                    {
                        ++curLine;
                        curPos = 0;
                    }
                    else
                    {
                        ++curPos;
                    }
                }

                while (reader.Peek() >= 0)
                {
                    c = (char)reader.Read();
                    if (char.IsWhiteSpace(c))
                    {
                        if (acc.Length > 0)
                        {
                            if (double.TryParse(acc.ToString(), out double d))
                            {
                                acc.Clear();
                                yield return Token.CreateDouble(d);
                            }
                            else
                            {
                                this.ParseError = true;
                                this.Error = $"Failed to parse file {path.Replace("\\", "/")} - line {curLine} position {lastNumStartPos}.";
                                yield return Token.CreateError();
                                yield break;
                            }
                        }
                        if (c == '\n')
                        {
                            foundNewLine = true;
                            ++curLine;
                            curPos = 0;
                        }
                        else
                        {
                            ++curPos;
                        }
                    }
                    else
                    {
                        if (acc.Length == 0)
                        {
                            if (foundNewLine)
                            {
                                yield return Token.CreateNewLine();
                                foundNewLine = false;
                            }
                            lastNumStartPos = curPos;
                        }
                        acc.Append(c);
                        ++curPos;
                    }
                }

                if (acc.Length > 0)
                {
                    if (double.TryParse(acc.ToString(), out double d))
                    {
                        yield return Token.CreateDouble(d);
                    }
                    else
                    {
                        this.ParseError = true;
                        this.Error = $"Failed to parse file {path.Replace("\\", "/")} - line {curLine} position {lastNumStartPos}.";
                        yield return Token.CreateError();
                    }
                }
            }
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
                    this.Error = $"Failed to parse file {path.Replace("\\", "/")} - line {line} index {curLine}.";
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
                    this.Error = $"Failed to parse file {path.Replace("\\", "/")} - line {line} index {curLine}.";
                    result = null;
                    return false;
                }
                ++curLine;
            }
            result = acc.ToArray();
            return true;
        }
    }
}
