using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Threading;
using System.Windows.Threading;
using System.Management;
using System.Text;
using System.Text.RegularExpressions;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;

using DispatcherPriority = System.Windows.Threading.DispatcherPriority;

using Microsoft.Research.AuDotNet;

namespace Microsoft.Research.AuDotNet
{
  public class Utils
  {
    /// <summary>
    /// The default output console
    /// </summary>
    public static IConsole Out = new ConsoleConsole();

    /// <summary>
    /// Send text line.
    /// </summary>
    /// <param name="msg">The string to print</param>
    static public void WriteLine(string msg)
    {
      Out.WriteLine(msg);
    }

    /// <summary>
    /// Send text line, in given foreground color
    /// </summary>
    /// <param name="msg">The string to print</param>
    static public void WriteLine(ConsoleColor fg, string msg)
    {
      Out.WriteLine(fg, msg);
    }

    static Stack<IConsole> pushed_tws = new Stack<IConsole>();

    /// <summary>
    /// Push a console onto the output stream stack.
    /// This becomes the destination for subsequent Writes
    /// until Popconsole() is called.
    /// </summary>
    /// <param name="tw"></param>
    static public void PushConsole(IConsole tw)
    {
      pushed_tws.Push(Out);
      Out = tw;
    }

    /// <summary>
    /// Restore the previous output stream.
    /// Exceptions in pop are generally logic errors, so are allowed to propagate.
    /// </summary>
    static public void PopConsole()
    {
      Out = pushed_tws.Pop();
    }

    /// <summary>
    /// Scroll a FlowDocumentScrollViewer to its end.
    /// Seems to sometimes fail, even when the ScrollViewer is found...
    /// </summary>
    /// <param name="fdsv">The FlowDocumentScrollViewer to whose end to scroll</param>
    /// <param name="distance_threshold">If nonzero, don't scroll if the viewport is currently more than this distance from the end</param>
    static public void ScrollToEnd(FlowDocumentScrollViewer fdsv, double distance_threshold)
    {
      DependencyObject obj = fdsv;

      while (obj != null && !(obj is ScrollViewer))
      {
        if (VisualTreeHelper.GetChildrenCount(obj) > 0)
          obj = VisualTreeHelper.GetChild(obj as Visual, 0);
        else
          obj = null;
      }

      ScrollViewer sv = obj as ScrollViewer;
      if (sv != null)
      {
        if (distance_threshold == 0 || sv.VerticalOffset > sv.ExtentHeight - distance_threshold)
          sv.ScrollToEnd();
      }
    }

    /// <summary>
    /// Fill array <paramref name="a"/> with <paramref name="value"/>.
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="a"></param>
    /// <param name="value"></param>
    static public void Fill<T>(T[] a, T value)
    {
      for (int i = 0; i < a.Length; ++i)
        a[i] = value;
    }

    /// <summary>
    /// Fill array <paramref name="a"/> with <paramref name="value"/>.
    /// </summary>
    /// <param name="a"></param>
    /// <param name="value"></param>
    static public void Fill<T>(T[,] a, T value)
    {
      for (int i = a.GetLowerBound(0); i <= a.GetUpperBound(0); ++i)
        for (int j = a.GetLowerBound(1); j <= a.GetUpperBound(1); ++j)
          a[i, j] = value;
    }

    /// <summary>
    /// Compare items for equality, where either object may be null
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="a"></param>
    /// <param name="b"></param>
    /// <returns></returns>
    public static bool SafeEquals<T>(T a, T b)
    {
      bool aIsNull = object.ReferenceEquals(a, null);
      bool bIsNull = object.ReferenceEquals(b, null);
      if (aIsNull) return bIsNull;
      if (bIsNull) return false; // a is not null
      return a.Equals(b);
    }


    /// <summary>
    /// Compare arrays for equality
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="a"></param>
    /// <param name="b"></param>
    /// <returns></returns>
    static public bool IsValueEqual<T>(T[] a, T[] b)
    {
      for (int i = 0; i < a.Length; ++i)
        if (!a[i].Equals(b[i]))
          return false;
      return true;
    }

    /// <summary>
    /// Compare arrays for equality
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="a"></param>
    /// <param name="b"></param>
    /// <returns></returns>
    static public bool IsValueEqual<T>(T[,] a, T[,] b)
    {
      bool aIsNull = object.ReferenceEquals(a, null);
      bool bIsNull = object.ReferenceEquals(b, null);
      if (aIsNull) return bIsNull;
      if (bIsNull) return false; // a is not null

      System.Collections.IEnumerator iter = a.GetEnumerator();
      foreach (T item in b)
      {
        iter.MoveNext();
        if (!SafeEquals<T>((T)iter.Current, item))
          return false;
      }
      return true;
    }

    /// <summary>
    /// Compare collections for equality
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="a"></param>
    /// <param name="b"></param>
    /// <returns></returns>
    public static bool IsValueEqual<T>(ICollection<T> a, ICollection<T> b)
    {
      if (a.Count != b.Count) return false;
      if (a.Count == 0) return true;
      IEnumerator<T> iter = a.GetEnumerator();
      foreach (T item in b)
      {
        iter.MoveNext();
        if (!SafeEquals<T>(iter.Current, item)) return false;
      }
      return true;
    }

    /// <summary>
    /// Save 2D array <paramref name="array"/> to text file.
    /// </summary>
    /// <param name="array"></param>
    /// <param name="filename"></param>
    static public void Save<T>(T[,] array, string filename)
    {
      using (System.IO.StreamWriter file = new System.IO.StreamWriter(filename))
      {
        for (int i = array.GetLowerBound(0); i <= array.GetUpperBound(0); ++i)
        {
          for (int j = array.GetLowerBound(1); j <= array.GetUpperBound(1); ++j)
          {
            file.Write(array[i, j] + " ");
          }
          file.WriteLine();
        }
      }
    }

    /// <summary>
    /// Load 2D array <paramref name="array"/> from text file.
    /// </summary>
    /// <param name="filename">The name of the file</param>
    static public double[,] LoadMatrix(string filename)
    {
      List<double[]> data = new List<double[]>();
      int cols = -1;
      int rows = 0;

      using (System.IO.StreamReader file = new System.IO.StreamReader(filename))
      {
        while (!file.EndOfStream)
        {
          string line = file.ReadLine();
          line.TrimEnd(new char[] { ' ', '\t' });
          string[] words = System.Text.RegularExpressions.Regex.Split(line, "[ \t]+");
          int len = words.Length;
          while (String.IsNullOrWhiteSpace(words[len - 1]))
            --len;
          if (cols == -1)
            cols = len;
          else if (cols != len)
            throw new Exception("cols don't match");
          double[] row = new double[cols];
          for (int j = 0; j < cols; ++j)
            row[j] = Double.Parse(words[j]);
          data.Add(row);
          ++rows;
        }
      }

      double[,] ret = new double[rows, cols];
      int i = 0;
      foreach (var row in data)
      {
        for (int j = 0; j < cols; ++j)
          ret[i, j] = row[j];
        ++i;
      }
      return ret;
    }

    /// <summary>
    /// Save vector to file
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="array"></param>
    /// <param name="filename"></param>
    static public void Save<T>(T[] array, string filename)
    {
      using (System.IO.StreamWriter file = new System.IO.StreamWriter(filename))
      {
        for (int i = 0; i < array.Length; ++i)
          file.WriteLine(array[i]);
      }
    }

    /// <summary>
    /// Convert Array3D of bytes to a BitmapSource.
    /// Assumes the array is HxWx3.
    /// </summary>
    /// <param name="a">The array3d</param>
    /// <param name="dpi">DPI needed for the BitmapSource. 96 is often good.</param>
    /// <returns></returns>
    static public BitmapSource Array3DToBitmapSource(Array3D<byte> a, int dpi)
    {
      if (a.Depth != 3)
        throw new ArgumentOutOfRangeException("rgb");

      return BitmapSource.Create(a.Cols, a.Rows, dpi, dpi, PixelFormats.Rgb24, null, a.Data, a.Cols * a.Depth);
    }

    /// <summary>
    /// Return the common prefix of a set of strings
    /// E.g. The input sequence
    ///      "Piglet's", "Pigeon", "Pie"
    /// would yield "Pi"
    /// </summary>
    /// <param name="strings">The input sequence</param>
    /// <returns>The common prefix</returns>
    static public string CommonPrefix(IEnumerable<string> strings)
    {
      string prefix = "";
      bool first = true;
      foreach (string s in strings)
      {
        if (first)
        {
          first = false;
          prefix = s;
        }
        else
        {
          while (!s.StartsWith(prefix, StringComparison.CurrentCultureIgnoreCase) &&
                 (prefix.Length > 0))
          {
            prefix = prefix.Substring(0, prefix.Length - 1);
          }
        }
      }
      return prefix;
    }

    /// <summary>
    /// Pretty-print a Linq Expression
    /// </summary>
    /// <typeparam name="T">Expression type, e.g. Expression<Func<bool>> </typeparam>
    /// <param name="f">The expression</param>
    /// <returns>The pretty printed expression</returns>
    static public string ToString<T>(Expression<T> f)
    {
      string msg = f.ToString();
      msg = Regex.Replace(msg, @"value\([^)]+\)\.", "");
      msg = Regex.Replace(msg, @"^\(\) => \((.*)\)$", @"$1");
      msg = Regex.Replace(msg, @"^\(\) => ", "");
      return msg;
    }

    /// <summary>
    /// Get all descendents of a given PID
    /// </summary>
    /// <param name="pid">The Process ID whose children to get</param>
    /// <returns></returns>
    static public IEnumerable<int> GetAllDescendantProcesses(int pid)
    {
      yield return pid;
      string wmi_query = "Select * From Win32_Process Where ParentProcessID=" + pid;
      using (var searcher = new System.Management.ManagementObjectSearcher(wmi_query))
      using (System.Management.ManagementObjectCollection moc = searcher.Get())
        foreach (System.Management.ManagementObject mo in moc)
        {
          int id = Convert.ToInt32(mo["ProcessID"]);
          foreach(int id0 in GetAllDescendantProcesses(id))
            yield return id0;
        }
    }
  }
}
