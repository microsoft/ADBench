using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace DotnetRunner.Data
{

    // rows is nrows+1 vector containing
    // indices to cols and vals. 
    // rows[i] ... rows[i+1]-1 are elements of i-th row
    // i.e. cols[row[i]] is the column of the first
    // element in the row. Similarly for values.
    public class BASparseMatrix
    {
        static readonly int BA_NCAMPARAMS = 11;

        int n, m, p; // number of cams, points and observations
        int nrows, ncols;
        List<int> rows;
        List<int> cols;
        List<double> vals;

        public BASparseMatrix() { }
        public BASparseMatrix(int n, int m, int p)
        {
            this.n = n;
            this.m = m;
            this.p = p;

            nrows = 2 * p + p;
            ncols = BA_NCAMPARAMS * n + 3 * m + p;
            rows = new List<int>(nrows + 1);
            int nnonzero = (BA_NCAMPARAMS + 3 + 1) * 2 * p + p;
            cols = new List<int>(nnonzero);
            vals = new List<double>(nnonzero);
            rows.Add(0);
        }

        public void InsertReprojErrBlock(int obsIdx,
            int camIdx, int ptIdx, double[] J) {

            int n_new_cols = BA_NCAMPARAMS + 3 + 1;
            rows.Add(rows.Last() + n_new_cols);
            rows.Add(rows.Last() + n_new_cols);

            for (int i_row = 0; i_row < 2; i_row++)
            {
                for (int i = 0; i < BA_NCAMPARAMS; i++)
                {
                    cols.Add(BA_NCAMPARAMS * camIdx + i);
                    vals.Add(J[2 * i + i_row]);
                }
                int col_offset = BA_NCAMPARAMS * n;
                int val_offset = BA_NCAMPARAMS * 2;
                for (int i = 0; i < 3; i++)
                {
                    cols.Add(col_offset + 3 * ptIdx + i);
                    vals.Add(J[val_offset + 2 * i + i_row]);
                }
                col_offset += 3 * m;
                val_offset += 3 * 2;
                cols.Add(col_offset + obsIdx);
                vals.Add(J[val_offset + i_row]);
            }
        }

        public void InsertWErrBlock(int wIdx, double w_d) {
            rows.Add(rows.Last() + 1);
            cols.Add(BA_NCAMPARAMS * n + 3 * m + wIdx);
            vals.Add(w_d);
        }

        void clear() {
            rows.Clear();
            cols.Clear();
            vals.Clear();
            rows.Add(0);
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

        BASparseMatrix J;
    }
}
