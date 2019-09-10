set srcdir=%1
set bindir=%2
set config=%3

dotnet build "%srcdir%/DiffSharpTests.fsproj" -c %config% -o %bindir%

rmdir /s /q "%srcdir%/obj"
