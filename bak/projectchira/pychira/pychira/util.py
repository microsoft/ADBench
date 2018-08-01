import ctypes, os

def get_chira_root():
    """Get the root of the Chira repository."""

    this_path = os.path.abspath(os.path.realpath(__file__))
    chira_root = os.path.abspath(os.path.join(this_path, '../../../'))

    return chira_root

def add_to_sys_path(path):

    import sys
    if path not in sys.path:
        sys.path.append(path)

def add_ezvtk_to_path():

    # Figure out ezvtk path.
    add_to_sys_path(os.path.join(get_chira_root(), 'ezvtk'))

def add_boost_python_to_dll_path():

    # See https://pytools.codeplex.com/workitem/1627
    AddDllDirectory = ctypes.windll.kernel32.SetDllDirectoryW
    AddDllDirectory.argtypes = [ctypes.c_wchar_p]
    AddDllDirectory(os.path.join(get_chira_root(), 'dependencies/python/boost.python/lib'))


def mkdir_dash_p(path):
    """Helper function that emulates mkdir -p to ensure a directory exists."""

    if not os.path.exists(path):
        os.makedirs(path)