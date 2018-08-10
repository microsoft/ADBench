call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" amd64
rem TODO remove hard paths

set bindir=C:/Users/Zak Smith/CMakeBuilds/95e43dd6-1979-0633-8dca-9ab4e04499c8/build/x64-Debug/tools/DiffSharp
set msbindir=C:/Program Files (x86)/Reference Assemblies/Microsoft/Framework/.NETFramework/v4.6.1
set assemblyfs=C:\Users\spike\AppData\Local\Temp\.NETFramework,Version=v4.6.1.AssemblyAttributes.fs


fsc.exe -o:"%bindir%/tool/DiffSharpTest.exe" --define:MODE_AD -r:"%bindir%/DiffSharp.dll" -r:"%bindir%/FsAlg.dll" -r:"%bindir%/FSharp.Core.dll" -r:"%bindir%/FSharp.Quotations.Evaluator.dll" -r:"%bindir%/MathNet.Numerics.dll" -r:"%bindir%/MathNet.Numerics.FSharp.dll" -r:"%msbindir%/mscorlib.dll" -r:"%msbindir%/System.Core.dll" -r:"%msbindir%/System.dll" -r:"%msbindir%/System.Numerics.dll" -r:"%msbindir%/System.Runtime.Serialization.dll" --target:exe %assemblyfs% AssemblyInfo.fs ba.fs gmm.fs hand.fs hand_d.fs Program.fs

rem -g --noframework --debug:full --define:DEBUG --define:TRACE --optimize- --tailcalls- --platform:anycpu32bitpreferred 
rem -r:"C:\Users\spike\Desktop\t2\DiffSharp\DiffSharpTest\packages\System.ValueTuple.4.4.0\lib\net461\System.ValueTuple.dll"
rem --warn:3 --warnaserror:76 --vserrors --preferreduilang:en-US --utf8output --fullpaths --flaterrors --subsystemversion:6.00 --highentropyva+