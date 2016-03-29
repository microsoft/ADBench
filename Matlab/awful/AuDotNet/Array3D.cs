using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Microsoft.Research.AuDotNet
{
    /// <summary>
    /// Bare-bones 3D array.
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public class Array3D<T>
    {
        T[] data;
        int rows;
        int cols;
        int depth;

        /// <summary>
        /// Construct a 3D array, of size <paramref name="rows"/>x<paramref name="cols"/>x<paramref name="depth"/>
        /// </summary>
        /// <param name="rows">First dimension</param>
        /// <param name="cols">Second dimension</param>
        /// <param name="depth">Third dimension</param>
        public Array3D(int rows, int cols, int depth)
        {
            this.rows = rows;
            this.cols = cols;
            this.depth = depth;
            data = new T[rows * cols * depth];
        }

        public int Rows { get { return rows; } }
        public int Cols { get { return cols; } }
        public int Depth { get { return depth; } }
        public T[] Data { get { return data; } }

        /// <summary>
        /// Fill with constant value
        /// </summary>
        /// <param name="val">The value with which to fill</param>
        public void Fill(T val)
        {
            for (int k = 0; k < rows * cols * depth; ++k)
                data[k] = val;
        }

        /// <summary>
        /// Range-checked Set of a (row, column) indexed slice.
        /// </summary>
        /// <param name="r"></param>
        /// <param name="c"></param>
        /// <param name="val"></param>
        public void Set(int r, int c, T[] val)
        {
            if (val.Length != depth)
                throw new ArgumentOutOfRangeException("val");
            if (r < 0 || r >= rows)
                throw new ArgumentOutOfRangeException("r");
            if (c < 0 || c >= cols)
                throw new ArgumentOutOfRangeException("r");

            for (int k = 0; k < depth; ++k)
                data[(r * cols + c) * depth + k] = val[k];
        }

        /// <summary>
        /// Range-checked Set of an individual cell
        /// </summary>
        /// <param name="r"></param>
        /// <param name="c"></param>
        /// <param name="k"></param>
        /// <param name="val"></param>
        public void Set(int r, int c, int k, T val)
        {
            if (k < 0 || k >= depth)
                throw new ArgumentOutOfRangeException("val");
            if (r < 0 || r >= rows)
                throw new ArgumentOutOfRangeException("r");
            if (c < 0 || c >= cols)
                throw new ArgumentOutOfRangeException("c");

            data[(r * cols + c) * depth + k] = val;
        }
    }
}
