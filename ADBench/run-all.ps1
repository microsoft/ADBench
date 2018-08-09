# Accept command-line args
param([int]$global:nruns_f=10, [int]$global:nruns_J=10, [string]$global:tmpdir="")

# Assert function
function assert ($expr) {
    if (!(& $expr @args)) {
        throw "Assertion failed [$expr]"
    }
}

# Get source dir

$global:dir = split-path ($MyInvocation.MyCommand.Path)
assert { $global:dir -match 'ADbench$' }
$global:dir = Split-Path $global:dir

Write-Host "$global:dir"

# Load bindir variable
assert "Test-Path" "$global:dir/ADBench/cmake_vars.ps1"
. $global:dir/ADBench/cmake_vars.ps1

# Set tmpdir default
if (!$global:tmpdir) { $global:tmpdir = "$dir/tmp" }


# Custom Tool class
Class Tool {
	[string]$name
	[bool]$gmm_both
	[string]$type
	[bool]$gmm_use_defs

	# Static constants

	# GMM values - NOTE not all implemented for ceres
	static [int[]]$gmm_d_vals = @(2, 10) # @(2, 10, 20, 32, 64)
	static [int[]]$gmm_k_vals = @(5, 10, 25) # @(5, 10, 25, 50, 100, 200)

	static [string]$gmm_dir_in = "$dir/data/gmm/1k/"

	# Constructor
	Tool ([string]$name, [bool]$gmm_both, [string]$type, [bool]$gmm_defs) {
		$this.name = $name
		$this.gmm_both = $gmm_both
		$this.type = $type
		$this.gmm_use_defs = $gmm_defs
	}

	# Run all tests for this tool
	[void] runall () {
		Write-Host $this.name
		$this.testgmm("")
	}

	# Run a single test
	[void] run ([string]$objective, [string]$dir_in, [string]$dir_out, [string]$fn) {
		$cmd = ""
		$cmdargs = @($dir_in, $dir_out, $fn, $global:nruns_f, $global:nruns_J)
		if ($this.type -eq "bin") {
			$cmd = "$global:bindir\tools\$($this.name)\Tools-$($this.name)-$objective.exe"
		} elseif ($this.type -eq "py") {
			$objective = $objective.ToLower().Replace("-", "_")
			$cmd = "python"
			$cmdargs = @("$global:dir/tools/$($this.name)/$($this.name)_$objective.py") + $cmdargs
		}

		& $cmd @cmdargs
	}

	# Run all gmm tests for this tool
	[void] testgmm ([string]$type="") {
		if ($this.gmm_both -and !$type) {
			$this.testgmm("-FULL")
			$this.testgmm("-SPLIT")
			return
		}

		Write-Host "  GMM$type"

		$dir_out = "$global:tmpdir/gmm/$($this.name)/"
		if (-Not (Test-Path $dir_out)) { mkdir $dir_out }

		foreach ($d in [Tool]::gmm_d_vals) {
			Write-Host "    d=$d"
			foreach ($k in [Tool]::gmm_k_vals) {
				Write-Host "      K=$k"
				$obj = "GMM$type"
				if ($this.gmm_use_defs) { $obj += "-d$d-K$k" }
				$this.run($obj, [Tool]::gmm_dir_in, $dir_out, "gmm_d$($d)_K$($k)")
			}
		}
	}
}

# Full list of tools
$tools = @(
	[Tool]::new("Adept", 1, "bin", 0),
	[Tool]::new("ADOLC", 1, "bin", 0),
	[Tool]::new("Ceres", 0, "bin", 1),
	[Tool]::new("Manual", 0, "bin", 0),
	[Tool]::new("Autograd", 1, "py", 0)
	#[Tool]::new("Theano", $TRUE, "py")
)

# Run all tests on each tool
foreach ($tool in $tools) {
	$tool.runall()
}
