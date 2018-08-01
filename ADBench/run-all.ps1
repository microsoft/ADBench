function assert($expr)
{
    if (!(& $expr)) {
        throw "Assertion failed [$expr]"
    }
}

$dir = split-path ($MyInvocation.MyCommand.Path)
assert { $dir -match 'ADbench$' }
$dir = Split-Path $dir

Write-Host "$dir"

$bindir = 'C:\Users\Andrew Fitzgibbon\CMakeBuilds\9f453784-edfa-5e36-80b5-7cbdb5076dfb\build\x86-Debug'

function run($tool, $objective)
{
    & "$bindir\tools\$tool\Tools-$tool-$objective.exe" @args
}

run Manual GMM $dir/data/gmm/ $dir/tmp/gmm_ test 10 10


