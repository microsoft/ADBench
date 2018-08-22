# Accept command-line args
param([int]$nruns_f=10, [int]$nruns_J=10, [double]$time_limit=60, [string]$tmpdir="", [bool]$repeat=$FALSE)

# Assert function
function assert ($expr) {
    if (!(& $expr @args)) {
        throw "Assertion failed [$expr]"
    }
}

# Get source dir

$dir = split-path ($MyInvocation.MyCommand.Path)
assert { $dir -match 'ADbench$' }
$dir = Split-Path $dir

Write-Host "Root Directory: $dir"

# Load cmake variables
assert Test-Path "$dir/ADBench/cmake_vars.ps1"
. $dir/ADBench/cmake_vars.ps1

# Set tmpdir default
if (!$tmpdir) { $tmpdir = "$dir/tmp" }
$tmpdir += "/$buildtype"

$datadir = "$dir/data"


# Custom Tool class
Class Tool {
	[string]$name
	[string]$type
	[array]$objectives
	[bool]$gmm_both
	[bool]$gmm_use_defs
	[array]$eigen_config

	# Static constants
	static [string]$gmm_dir_in = "$datadir/gmm/"
	static [string]$ba_dir_in = "$datadir/ba/"
	static [string]$hand_dir_in = "$datadir/hand/"
	static [array]$gmm_sizes = @("1k", "10k") # @("1k", "10k", "2.5M")
	static [array]$hand_sizes = @("small", "big") # @("small", "big")
	static [int]$ba_min_n = 1
	static [int]$ba_max_n = 5
	static [int]$hand_min_n = 1
	static [int]$hand_max_n = 5

	# Constructor
	Tool ([string]$name, [string]$type, [string]$objectives, [bool]$gmm_both, [bool]$gmm_use_defs, [string]$eigen_config) {
		$this.name = $name
		$this.type = $type
		$this.objectives = $objectives.ToCharArray() | % { $_ -band "1" }
		$this.gmm_both = $gmm_both
		$this.gmm_use_defs = $gmm_use_defs
		$this.eigen_config = $eigen_config.ToCharArray() | % { $_ -band "1" }
	}

	# Run all tests for this tool
	[void] runall () {
		Write-Host $this.name
		if ($this.objectives[0]) { $this.testgmm() }
		if ($this.objectives[1]) { $this.testba() }
		if ($this.objectives[2]) { $this.testhand() }
	}

	# Run a single test
	[void] run ([string]$objective, [string]$dir_in, [string]$dir_out, [string]$fn) {
		if ($objective.contains("Eigen")) { $out_name = "$($this.name.ToLower())_eigen" }
		elseif ($objective.contains("Light")) { $out_name = "$($this.name.ToLower())_light" }
		elseif ($objective.endswith("SPLIT")) { $out_name = "$($this.name)_split" }
		else { $out_name = $this.name }
		$output_file = "$($dir_out)$($fn)_times_$($out_name).txt"
		if (!$script:repeat -and (Test-Path $output_file)) {
			Write-Host "          Skipped test (already completed)"
			return
		}

		$cmd = ""
		$cmdargs = @($dir_in, $dir_out, $fn, $script:nruns_f, $script:nruns_J, $script:time_limit)
		if ($this.type -eq "bin") {
			$cmd = "$script:bindir\tools\$($this.name)\Tools-$($this.name)-$objective.exe"
		} elseif ($this.type -eq "py" -or $this.type -eq "pybat") {
			$objective = $objective.ToLower().Replace("-", "_")
			if ($this.type -eq "py") { $cmd = "python" }
			elseif ($this.type -eq "pybat") { $cmd = "$script:dir/tools/$($this.name)/run.bat" }
			$cmdargs = @("$script:dir/tools/$($this.name)/$($this.name)_$objective.py") + $cmdargs
		} elseif ($this.type -eq "matlab") {
			$objective = $objective.ToLower().Replace("-", "_")
			$cmd = "matlab"
			$cmdargs = @("-wait", "-nosplash", "-nodesktop", "-r", "cd '$script:dir/tools/$($this.name)/'; addpath('$script:bindir/tools/$($this.name)/'); $($this.name)_$objective $cmdargs; quit")
		}

		$output = & $cmd @cmdargs
		foreach($line in $output) {
			Write-Host "          $line"
		}
	}

	# Run all gmm tests for this tool
	[void] testgmm () {
		$objs = @()
		if ($this.eigen_config[0]) { $objs += @("GMM") }
		if ($this.eigen_config[1]) { $objs += @("GMM-Eigen") }

		if ($this.gmm_both) { $types = @("-FULL", "-SPLIT") }
		else { $types = @("") }

		foreach ($obj in $objs) {
			foreach ($type in $types) {
				Write-Host "  $obj$type"

				foreach ($sz in [Tool]::gmm_sizes) {
					Write-Host "    $sz"

					$dir_in = "$([Tool]::gmm_dir_in)$sz/"
					$dir_out = "$script:tmpdir/gmm/$sz/$($this.name)/"
					if (!(Test-Path $dir_out)) { mkdir $dir_out }

					foreach ($d in $script:gmm_d_vals) {
						Write-Host "      d=$d"
						foreach ($k in $script:gmm_k_vals) {
							Write-Host "        K=$k"
							$run_obj = "$obj$type"
							if ($this.gmm_use_defs) { $run_obj += "-d$d-K$k" }
							$this.run($run_obj, $dir_in, $dir_out, "gmm_d$($d)_K$($k)")
						}
					}
				}
			}
		}
	}

	# Run all BA tests for this tool
	[void] testba () {
		$objs = @()
		if ($this.eigen_config[2]) { $objs += @("BA") }
		if ($this.eigen_config[3]) {$objs += @("BA-Eigen") }

		$dir_out = "$script:tmpdir/ba/$($this.name)/"
		if (!(Test-Path $dir_out)) { mkdir $dir_out }

		foreach ($obj in $objs) {
			Write-Host "  $obj"

			for ($n = [Tool]::ba_min_n; $n -le [Tool]::ba_max_n; $n++) {
				Write-Host "    $n"
				$this.run("$obj", [Tool]::ba_dir_in, $dir_out, "ba$n")
			}
		}
	}

	# Run all Hand tests for this tool
	[void] testhand () {
		$objs = @()
		if ($this.eigen_config[4]) {
			if ($this.type -eq "bin") { $objs += @("Hand-Light") }
			else { $objs += @("Hand") }
		}
		if ($this.eigen_config[5]) { $objs += @("Hand-Eigen") }

		foreach ($obj in $objs) {
			Write-Host "  $obj"

			foreach ($type in @("simple", "complicated")) {
				foreach ($sz in [Tool]::hand_sizes) {
					Write-Host "    $($type)_$sz"

					$dir_in = "$([Tool]::hand_dir_in)$($type)_$sz/"
					$dir_out = "$script:tmpdir/hand/$($type)_$sz/$($this.name)/"
					if (!(Test-Path $dir_out)) { mkdir $dir_out }

					for ($n = [Tool]::hand_min_n; $n -le [Tool]::hand_max_n; $n++) {
						Write-Host "      $n"
						$this.run("$obj-$($type)", $dir_in, $dir_out, "hand$n")
					}
				}
			}
		}
	}
}

# Full list of tools
$tools = @(
	[Tool]::new("Adept", "bin", "111", 1, 0, "101010"),
	[Tool]::new("ADOLC", "bin", "111", 1, 0, "101011"),
	[Tool]::new("Ceres", "bin", "110", 0, 1, "101011"),
	[Tool]::new("Finite", "bin", "111", 0, 0, "101011"),
	[Tool]::new("Manual", "bin", "111", 0, 0, "110101"),
	[Tool]::new("DiffSharp", "bin", "010", 1, 0, "101010"),
	[Tool]::new("Autograd", "py", "110", 1, 0, "101010"),
	[Tool]::new("PyTorch", "py", "100", 0, 0, "101010"),
	[Tool]::new("Theano", "pybat", "111", 0, 0, "101010")
	#[Tool]::new("MuPad", "matlab", 0, 0, 0)
	#[Tool]::new("ADiMat", "matlab", 0, 0, 0)
)

# Run all tests on each tool
foreach ($tool in $tools) {
	$tool.runall()
}
