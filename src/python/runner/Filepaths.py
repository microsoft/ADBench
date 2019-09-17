def filepath_to_basename(filepath):
    last_slash_position = filepath.rfind("/")
    filename = filepath if last_slash_position == -1 else filepath[last_slash_position + 1:]

    dot = filename.rfind('.')
    basename = filename if dot == -1 else filename[0:dot]

    return basename

def modulepath_to_basename(filepath):
    last_slash_position = filepath.rfind("/")
    filename = filepath if last_slash_position == -1 else filepath[last_slash_position + 1:]

    # python module name should contain "GMM", "BA", "Hand" or "LSTM" at the end
    basename = filename[: max(filename.rfind("GMM"), filename.rfind("BA"), filename.rfind("Hand"), filename.rfind("LSTM"))]

    return basename

def filepath_to_dirname(filepath):
    last_slash_position = filepath.rfind("/")
    dirname = "./" if last_slash_position == -1 else filepath[:last_slash_position + 1]

    return dirname