function assert ($expr) {
    if (!(& $expr)) {
        throw "Assertion failed [$expr]"
    }
}


# Basic variables

$dir = split-path ($MyInvocation.MyCommand.Path)
assert { $dir -match 'ADbench$' }
$dir = Split-Path $dir

Write-Host "$dir"

# $bindir = 'C:\Users\Andrew Fitzgibbon\CMakeBuilds\9f453784-edfa-5e36-80b5-7cbdb5076dfb\build\x86-Debug'
$bindir = 'C:\Users\Zak Smith\CMakeBuilds\95e43dd6-1979-0633-8dca-9ab4e04499c8\build\x64-Debug'


# Functions to run tools

# Main run function
function run ($type, $tool, $objective) {
	if ($type -eq "bin") {
		runbin $tool $objective @args
	} elseif ($type -eq "py") {
		runpy $tool $objective @args
	}
}

# Run binary tool
function runbin ($tool, $objective) {
    & "$bindir\tools\$tool\Tools-$tool-$objective.exe" @args
}

# Run python tool
function runpy ($tool, $objective) {
	& "python" "$dir/tools/$tool/$($tool)_$objective.py" @args
}


# Functions to run tests

# Run all gmm tests for a tool
function testgmm($tool, $type) {
	Write-Host "  GMM"

	$dir_in = "$dir/data/gmm/1k/"
	$dir_out = "$dir/tmp/gmm/$tool/"

	$d_all = @(2, 10) # @(2, 10, 20, 32, 64)
	$k_all = @(5, 10, 25) # @(5, 10, 25, 50, 100, 200)
	# NOTE not all implemented for ceres

	if (-Not (Test-Path $dir/tmp/gmm/$tool)) { mkdir $dir/tmp/gmm/$tool }
	foreach ($d in $d_all) {
		Write-Host "    d=$d"
		foreach ($k in $k_all) {
			Write-Host "      K=$k"
			if ($tool -eq "Ceres") {
				run $type $tool GMM-d$d-K$k $dir_in $dir_out gmm_d$($d)_K$($k) 10 10
			} else {
				run $type $tool GMM $dir_in $dir_out gmm_d$($d)_K$($k) 10 10
			}
		}
	}
}

# Tools

# Custom Tool class
Class Tool {
	[string]$name
	[bool]$gmm_both

	# Constructor
	Tool ([string]$name, [bool]$gmm_both, [string]$type) {
		$this.name = $name
		$this.gmm_both = $gmm_both
		if ($type) {
			$this.type = $type
		} else {
			$this.type = "bin"
		}
	}

	# Run all tests for this tool
	runall () {
		Write-Host $this.name
		if ($this.gmm_both) {

		} else {
			testgmm $this.name $this.type
		}
	}

	# TODO move all other functions into this class
	# and put the $this.gmm_both testing within testgmm
	# NOTE have built as -GMM-FULL.exe and -GMM-SPLIT.exe
}

# Full list of tools
$tools = @(
	[Tool]::new("Adept", 1),
	[Tool]::new("ADOLC", 1),
	[Tool]::new("Ceres"),
	[Tool]::new("Manual")
	[Tool]::new("Autograd", 1, "py")
	[Tool]::new("Theano", 1, "py")
)


# Run all tests

# Create temp dir
if (-Not (Test-Path $dir/tmp)) { mkdir $dir/tmp }

# Run all tests on each tool
foreach ($tool in $tools) {
	$tool.runall()
}
