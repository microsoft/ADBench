SET currentdir=%cd%
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\Tools\VsDevCmd.bat"
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\Tools\VsMSBuildCmd.bat"
cd %currentdir%
set INCLUDE="%INCLUDE%C:\Users\Zak Smith\Downloads\boost_1_67_0;C:\ZS\autodiff\submodules\adol-c\MSVisualStudio\v14\nosparse;"
msbuild /t:build ./submodules/adol-c/MSVisualStudio/v14/adolc.vcxproj /p:WarningLevel=0;Configuration=nosparse;PlatformToolset=v141;WindowsTargetPlatformVersion=10.0.16299.0;useenv=true;OutDir=%currentdir%\bin\;BaseIntermediateOutputPath=c:\zs\autodiff\bin\;IntermediateOutputPath=c:\zs\autodiff\bin\
