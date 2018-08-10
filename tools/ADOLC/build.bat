set srcdir=%1
set bindir=%2
set boostdir=%3

call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" amd64
rem TODO remove hard paths

set INCLUDE="%INCLUDE%%srcdir%/MSVisualStudio/v14/x64/nosparse;%boostdir%;%srcdir%/MSVisualStudio/v14/nosparse;"

msbuild /t:build %srcdir%/MSVisualStudio/v14/adolc.vcxproj /p:Configuration=nosparse;useenv=true;OutDir=%bindir%/;BaseIntermediateOutputPath=%bindir%/obj/;IntermediateOutputPath=%bindir%/obj/;PlatformToolset=v141;WindowsTargetPlatformVersion=10.0.16299.0;PlatformTarget=x64;Platform=x64
