set bindir="C:/Users/Zak Smith/CMakeBuilds/95e43dd6-1979-0633-8dca-9ab4e04499c8/build/x64-Debug/tools/DiffSharp"

call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" amd64
rem TODO remove hard paths


rem TODO remove hard paths


set dsdir=C:/ZS/autodiff/submodules/DiffSharp

dotnet build %dsdir%/src/DiffSharp/Diffsharp.fsproj -o %bindir%
rmdir /s /q "%dsdir%/src/DiffSharp/obj"


set mndir=C:/ZS/autodiff/submodules/mathnet-numerics

dotnet build %mndir%/src/FSharp/FSharp.fsproj -o %bindir%
rmdir /s /q "%mndir%/src/FSharp/obj"

dotnet build %mndir%/src/Numerics/Numerics.csproj -o %bindir%
rmdir /s /q "%mndir%/src/Numerics/obj"


set fadir=C:/ZS/autodiff/submodules/FsAlg
msbuild %fadir%/src/FsAlg/FsAlg.fsproj /p:OutDir=%bindir%;OutputPath=%bindir%;BaseIntermediateOutputPath=%bindir%/obj/;IntermediateOutputPath=%bindir%/obj/


set fqdir=C:/ZS/autodiff/submodules/FSharp.Quotations.Evaluator
dotnet build %fqdir%/src/FSharp.Quotations.Evaluator/FSharp.Quotations.Evaluator.fsproj -o %bindir%
rmdir /s /q %fqdir%/src/FSharp.Quotations.Evaluator/obj

rem TODO the set stuff in cmake
