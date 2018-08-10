# Accept command-line args
param([int]$script:nruns_f=10, [int]$script:nruns_J=10, [string]$script:tmpdir="")

# Assert function
function assert ($expr) {
    if (!(& $expr @args)) {
        throw "Assertion failed [$expr]"
    }
}

# Get source dir

$script:dir = split-path ($MyInvocation.MyCommand.Path)
assert { $script:dir -match 'ADbench$' }
$script:dir = Split-Path $script:dir

Write-Host "$script:dir"

# Load bindir variable
assert "Test-Path" "$script:dir/ADBench/cmake_vars.ps1"
. $script:dir/ADBench/cmake_vars.ps1

# Set tmpdir default
if (!$script:tmpdir) { $script:tmpdir = "$dir/tmp" }


# Custom Tool class
Class Tool {
	[string]$name
	[bool]$gmm_both
	[string]$type
	[bool]$gmm_use_defs

	# Static constants
	static [string]$gmm_dir_in = "$dir/data/gmm/1k/"
	static [string]$ba_dir_in = "$dir/data/ba/"
	static [int]$ba_min_n = 1
	static [int]$ba_max_n = 20

	# Constructor
	Tool ([string]$name, [bool]$gmm_both, [string]$type, [bool]$gmm_use_defs) {
		$this.name = $name
		$this.gmm_both = $gmm_both
		$this.type = $type
		$this.gmm_use_defs = $gmm_use_defs
	}

	# Run all tests for this tool
	[void] runall () {
		Write-Host $this.name
		$this.testgmm("")
		$this.testba()
	}

	# Run a single test
	[void] run ([string]$objective, [string]$dir_in, [string]$dir_out, [string]$fn) {
		$cmd = ""
		$cmdargs = @($dir_in, $dir_out, $fn, $script:nruns_f, $script:nruns_J)
		if ($this.type -eq "bin") {
			$cmd = "$script:bindir\tools\$($this.name)\Tools-$($this.name)-$objective.exe"
		} elseif ($this.type -eq "py") {
			$objective = $objective.ToLower().Replace("-", "_")
			$cmd = "python"
			$cmdargs = @("$script:dir/tools/$($this.name)/$($this.name)_$objective.py") + $cmdargs
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

		$dir_out = "$script:tmpdir/gmm/$($this.name)/"
		if (-Not (Test-Path $dir_out)) { mkdir $dir_out }

		foreach ($d in $script:gmm_d_vals) {
			Write-Host "    d=$d"
			foreach ($k in $script:gmm_k_vals) {
				Write-Host "      K=$k"
				$obj = "GMM$type"
				if ($this.gmm_use_defs) { $obj += "-d$d-K$k" }
				$this.run($obj, [Tool]::gmm_dir_in, $dir_out, "gmm_d$($d)_K$($k)")
			}
		}
	}

	# Run all BA tests for this tool
	[void] testba () {
		Write-Host "  BA"

		$dir_out = "$script:tmpdir/ba/$($this.name)/"
		if (-Not (Test-Path $dir_out)) { mkdir $dir_out }

		for ($n = [Tool]::ba_min_n; $n -le [Tool]::ba_max_n; $n++) {
			Write-Host "    $n"
			$this.run("BA", [Tool]::ba_dir_in, $dir_out, "ba$n")
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
