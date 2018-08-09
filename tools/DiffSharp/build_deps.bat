set dsdir=C:/ZS/autodiff/submodules/DiffSharp
set bindir="C:/Users/Zak Smith/CMakeBuilds/95e43dd6-1979-0633-8dca-9ab4e04499c8/build/x64-Debug/tools/DiffSharp"

dotnet build %dsdir%/src/DiffSharp/Diffsharp.fsproj -o %bindir%
rmdir /s /q "%dsdir%/src/DiffSharp/obj"


set mndir=C:/ZS/autodiff/submodules/mathnet-numerics

dotnet build %mndir%/src/FSharp/FSharp.fsproj -o %bindir%
rmdir /s /q "%mndir%/src/FSharp/obj"

dotnet build %mndir%/src/Numerics/Numerics.csproj -o %bindir%
rmdir /s /q "%mndir%/src/Numerics/obj"

rem this works, now do the set stuff in cmake
