# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import os

def filepath_to_basename(filepath):
    filename = os.path.basename(filepath)
    return os.path.splitext(filename)[0]

def modulepath_to_basename(filepath):
    filename = os.path.basename(filepath)

    # python module name should contain "GMM", "BA", "Hand" or "LSTM" at the end
    pos = max(
        filename.rfind("GMM"),
        filename.rfind("BA"),
        filename.rfind("Hand"),
        filename.rfind("LSTM")
    )

    basename = filename[: pos]
    return basename

def filepath_to_dirname(filepath):
    dirname = os.path.dirname(filepath)
    if not dirname:
        dirname = "."

    return dirname