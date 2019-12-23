import glob

copyright_header = [ "Copyright (c) Microsoft Corporation.",
                     "Licensed under the MIT license." ]

to_comment = { "py": lambda x: "# " + x }

def line_ending_type(b):
    rns = b.count(b'\r\n')
    ns  = b.count(b'\n')
    rs  = b.count(b'\r')

    windows = rns
    unix    = ns - rns
    macos   = rs = rns

    print(windows, unix, macos)

def example():
    from sys import argv

    with open(argv[1], 'rb') as f:
        line_ending_type(f.read())

def main():
    paths = glob.iglob('**/*.py', recursive=True)

    for p in paths:
        print(p)
        with open(p, 'r') as f:
            content = f.read()
            print(to_commo
            print(content)

if __name__ == '__main__': main()
