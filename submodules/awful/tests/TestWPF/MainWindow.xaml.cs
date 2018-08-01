using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace TestWPF
{
  /// <summary>
  /// The runtime datacontext -- this might have been loaded from disk.
  /// </summary>
  public class RunTimeData
  {
    public string ProjectDir
    {
      get { return "The runtime directory"; }
    }
  }

    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
          InitializeComponent();
        }

        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
          this.DataContext = new RunTimeData();
        }
    }
}
