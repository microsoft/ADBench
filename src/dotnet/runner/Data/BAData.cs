// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace DotnetRunner.Data
{
    public class BASparseMatrix
    {
        static readonly int BA_NCAMPARAMS = 11;

        // number of cams, points and observations
        /// <summary>
        /// Number of cams
        /// </summary>
        public int N { get; private set; }
        /// <summary>
        /// Number of points
        /// </summary>
        public int M { get; private set; }
        /// <summary>
        /// Number of observations
        /// </summary>
        public int P { get; private set; }
        public int NRows { get; }
        public int NCols { get; }
        /// <summary>
        /// int[nrows + 1]. Defined recursively as follows:
        /// rows[0] = 0
        /// rows[i] = rows[i - 1] + the number of nonzero elements on the i-1 row of the matrix
        /// </summary>
        public List<int> Rows { get; } = new List<int>();
        /// <summary>
        /// Column index in the matrix of each element of vals. Has the same size
        /// </summary>
        public List<int> Cols { get; } = new List<int>();
        /// <summary>
        /// All the nonzero entries of the matrix in the left-to-right top-to-bottom order
        /// </summary>
        public List<double> Vals { get; } = new List<double>();

        public BASparseMatrix(int n, int m, int p)
        {
            this.N = n;
            this.M = m;
            this.P = p;

            NRows = 2 * p + p;
            NCols = BA_NCAMPARAMS * n + 3 * m + p;
            Rows = new List<int>(NRows + 1);
            int nnonzero = (BA_NCAMPARAMS + 3 + 1) * 2 * p + p;
            Cols = new List<int>(nnonzero);
            Vals = new List<double>(nnonzero);
            Rows.Add(0);
        }

        public void InsertReprojErrBlock(int obsIdx,
            int camIdx, int ptIdx, double[] J)
        {

            int n_new_cols = BA_NCAMPARAMS + 3 + 1;
            Rows.Add(Rows.Last() + n_new_cols);
            Rows.Add(Rows.Last() + n_new_cols);

            for (int i_row = 0; i_row < 2; i_row++)
            {
                for (int i = 0; i < BA_NCAMPARAMS; i++)
                {
                    Cols.Add(BA_NCAMPARAMS * camIdx + i);
                    Vals.Add(J[2 * i + i_row]);
                }
                int col_offset = BA_NCAMPARAMS * N;
                int val_offset = BA_NCAMPARAMS * 2;
                for (int i = 0; i < 3; i++)
                {
                    Cols.Add(col_offset + 3 * ptIdx + i);
                    Vals.Add(J[val_offset + 2 * i + i_row]);
                }
                col_offset += 3 * M;
                val_offset += 3 * 2;
                Cols.Add(col_offset + obsIdx);
                Vals.Add(J[val_offset + i_row]);
            }
        }

        public void InsertWErrBlock(int wIdx, double w_d)
        {
            Rows.Add(Rows.Last() + 1);
            Cols.Add(BA_NCAMPARAMS * N + 3 * M + wIdx);
            Vals.Add(w_d);
        }

        void Clear()
        {
            Rows.Clear();
            Cols.Clear();
            Vals.Clear();
            Rows.Add(0);
        }
    };

    public class BAInput
    {
        public int N { get; set; }
        public int M { get; set; }
        public int P { get; set; }

        public double[][] Cams { get; set; }
        public double[][] X { get; set; }
        public double[] W { get; set; }
        public double[][] Feats { get; set; }

        public int[][] Obs { get; set; }
    };

    public class BAOutput
    {
        public double[] ReprojErr { get; set; }
        public double[] WErr { get; set; }
        public BASparseMatrix J { get; set; }
    }
}
