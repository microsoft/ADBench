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

# $bindir = 'C:\Users\Andrew Fitzgibbon\CMakeBuilds\9f453784-edfa-5e36-80b5-7cbdb5076dfb\build\x86-Debug'
$bindir = 'C:\Users\Zak Smith\CMakeBuilds\95e43dd6-1979-0633-8dca-9ab4e04499c8\build\x64-Debug'

function run($tool, $objective)
{
    & "$bindir\tools\$tool\Tools-$tool-$objective.exe" @args
}

if (-Not (Test-Path $dir/tmp)) { mkdir $dir/tmp }

$tools = @("Adept", "ADOLC", "Manual")

# GMM
$d_all = @(2, 10, 20) # @(2, 10, 20, 32, 64)
$k_all = @(5, 10) # @(5, 10, 25, 50, 100, 200)
if (-Not (Test-Path $dir/tmp/gmm)) { mkdir $dir/tmp/gmm }
foreach ($tool in $tools) {
	if (-Not (Test-Path $dir/tmp/gmm/$tool)) { mkdir $dir/tmp/gmm/$tool }
	foreach ($d in $d_all) {
		foreach ($k in $k_all) {
			run $tool GMM $dir/data/gmm/1k/ $dir/tmp/gmm/$tool/ gmm_d$($d)_K$($k) 10 10
		}
	}
}

<#run Adept GMM $dir/data/gmm/ $dir/tmp/gmm_ test 10 10
run Adept BA $dir/data/ba/ $dir/tmp/ba_ test 10 10
run ADOLC GMM $dir/data/gmm/ $dir/tmp/gmm_ test 10 10
run ADOLC BA $dir/data/ba/ $dir/tmp/ba_ test 10 10
run Ceres GMM $dir/data/gmm/ $dir/tmp/gmm_ test 10 10
run Manual GMM $dir/data/gmm/ $dir/tmp/gmm_ test 10 10
run Manual BA $dir/data/ba/ $dir/tmp/ba_ test 10 10#>
