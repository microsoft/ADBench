import glob

copyright_header = [ "Copyright (c) Microsoft Corporation.",
                     "Licensed under the MIT license." ]

hash_comment = lambda x: "# " + x
double_slash_comment = lambda x: "// " + x

to_comment = { "py": hash_comment,
               "jl": hash_comment,
               "h": double_slash_comment,
               "cpp": double_slash_comment,
               "c": double_slash_comment,
               "cxx": double_slash_comment,
               "cs": double_slash_comment
             }

# Byte order mark
BOM = "\ufeff"

def line_ending_type(b):
    rns = b.count(b'\r\n')
    ns  = b.count(b'\n')
    rs  = b.count(b'\r')

    windows = rns
    unix    = ns - rns
    macos   = rs

    print(windows, unix, macos)

def example():
    from sys import argv

    with open(argv[1], 'rb') as f:
        line_ending_type(f.read())

def main():
    for subdir in ["ADBench", "tools", "src", "data"]:
        for (extension, modifier) in to_comment.items():
            paths = glob.iglob(subdir + '/**/*.' + extension, recursive=True)

            for p in paths:
                print(p)
                with open(p, 'r') as f:
                    content = f.read()

                with open(p, 'w') as f:
                    have_bom = content[:1] == BOM
                    start_of_file = BOM if have_bom else ""
                    rest_of_content = content[1:] if have_bom else content

                    f.write(start_of_file)
                    for copyright_line in copyright_header:
                        f.write(modifier(copyright_line))
                        f.write("\n")
                    f.write("\n")
                    f.write(rest_of_content)

if __name__ == '__main__': main()
