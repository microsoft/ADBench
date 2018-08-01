=== ADBench autodiff benchmark ===

To run all benchmarks, there are a range of packages to update and confgure, which can be somewhat time consuming, 
but to check your install, just cmake and run ADBench/run-all.ps1, and at the least, manual C++ will be run.

Folder structure:

ADBench		Orchestration scripts, plotting etc
tools		Implementations for each tested tool, one folder per tool, with *-common folders for shared files by language
data		Data files for different examples 
Documents	Papers, presentations etc
packages	Packages from nuget
submodules	Dependencies on other git repositories
usr			Per-user scratch folder
tmp			Output of benchmark files, figures etc
