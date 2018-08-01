
AWFUL - The AWF Utilities Library

Author: Andrew W Fitzgibbon, awf at microsoft.com

Primarily Matlab, with some .NET bits in AuDotNet

MATLAB:

The au_ prefix in the matlab files is because it's important in
matlab's flat namespace that clashes of function names are avoided.

>> help awful/matlab
Gives a table of contents.

>> au_mexall
MEX the various things that need mexing.

>> au_run_tests
Runs lots of tests.

.NET:

Load awful.sln to run unit tests.
