$buildtype = "Release"
[double]$defaultRelativeTolerance = 1.0e-2;
[double]$defaultAbsoluteTolerance = 1.0e-6;
$maxGmmGradSizeForFinite = 10000;

# Make a directory (including its parents if necessary) after checking
# that nothing else is in the way.  See
#
#     https://github.com/awf/ADBench/pull/37#discussion_r288167348
function mkdir_p($path) {
   if (test-path -pathtype container $path)  {
         return
   } elseif (test-path $path) {
         error "There's something in the way"
   } else {
         new-item -itemtype directory $path
   }
}

function run_command ($cmd) {
	write-host "Run [$cmd $args]"
	$ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
	$ProcessInfo.FileName = $cmd
	$ProcessInfo.RedirectStandardError = $true
	$ProcessInfo.RedirectStandardOutput = $true
	$ProcessInfo.UseShellExecute = $false
	$ProcessInfo.Arguments = $args
	$Process = New-Object System.Diagnostics.Process
	$Process.StartInfo = $ProcessInfo
	try {
		$Process.Start() | Out-Null
	} catch {
		write-error "Failed to start process $cmd $args"
		throw "failed"
	}
	$Process.WaitForExit()
	$stdout = $Process.StandardOutput.ReadToEnd().Trim().Replace("`n", "`nstdout> ")
	$stderr = $Process.StandardError.ReadToEnd().Trim().Replace("`n", "`nstderr> ")
	$allOutput = "stdout> " + $stdout + "`nstderr> " + $stderr
	Write-Host "$allOutput"
}

function computeJ ([string]$objective, [string]$module, [string]$dir_in, [string]$dir_out, [string]$fn) {
	$output_file = "${dir_out}${fn}_J_${module}.txt"

	$cmd = "$script:bindir/src/cpp/runner/CppRunner.exe"
    $dir_name = $module.ToLowerInvariant()[0] + $module.Substring(1)
    $module_path = "$script:bindir/src/cpp/modules/$($dir_name)/$($module).dll"
    $task = $objective
	$cmdargs = @("$task $module_path $dir_in$fn.txt $dir_out 0 1 1 0")
    

	run_command $cmd @cmdargs
	if (!(test-path $output_file)) {
		throw "Command ran, but did not produce output file [$output_file]"
	}
    Remove-Item "${dir_out}${fn}_F_${module}.txt"
    Remove-Item "${dir_out}${fn}_times_${module}.txt"
    return $output_file
}

function computePartGmmJ ([string]$dir_in, [string]$dir_out, [string]$fn) {
	$output_files = @("${dir_out}${fn}_J_positions.txt", "${dir_out}${fn}_J_alphas.txt", "${dir_out}${fn}_J_means.txt", "${dir_out}${fn}_J_icfs.txt")

    $cmd = "$script:bindir/src/cpp/utils/finitePartialGmm/FinitePartialGmm.exe"
	$cmdargs = @("$dir_in$fn.txt $dir_out $maxGmmGradSizeForFinite")
    

	run_command $cmd @cmdargs
    foreach ($output_file in $output_files) {
	    if (!(test-path $output_file)) {
	    	throw "Command ran, but did not produce output file [$output_file]"
	    }
    }
    return $output_files
}


# Get source dir
$scriptdir = Split-Path ($MyInvocation.MyCommand.Path)
$dir = Split-Path $scriptdir

Write-Host "Root Directory: $dir"

Import-Module "$scriptdir/jacobian-comparison.psm1"
$comparer = Get-Comparer

# Load cmake variables
$cmake_vars = "$dir/ADBench/cmake-vars-$buildtype.ps1"
if (!(Test-Path $cmake_vars)) {
   throw "No cmake-vars file found at $cmake_vars. Remember to run cmake before running this script, and/or pass the -buildtype param."
}
. $cmake_vars

$outdir = "$dir/goldJ"

$datadir = "$dir/data"

Write-Host "Build Type: $buildtype, output to $outdir`n"

# Constants
[string]$gmm_dir_in = "$datadir/gmm/"
[string]$ba_dir_in = "$datadir/ba/"
[string]$hand_dir_in = "$datadir/hand/"
[string]$lstm_dir_in = "$datadir/lstm/"
[array]$gmm_sizes = @("1k", "10k", "2.5M")
[array]$hand_sizes = @("small", "big")
[int]$ba_min_n = 1
[int]$ba_max_n = 20
[int]$hand_min_n = 1
[int]$hand_max_n = 12
[array]$lstm_l_vals = @(2, 4)
[array]$lstm_c_vals = @(1024, 4096)

$errors = New-Object Collections.Generic.List[string]
$maxAbsDiff = 0.0
$maxRelDiff = 0.0

# Manual BA
Write-Host "Manually computing GMM gradients"
foreach ($sz in $gmm_sizes) {
	Write-Host "    $sz"

	$dir_in = "$gmm_dir_in$sz/"
	$dir_out = "$outdir/gmm/$sz/"
	mkdir_p $dir_out

	foreach ($d in $gmm_d_vals) {
		Write-Host "      d=$d"
		foreach ($k in $gmm_k_vals) {
			Write-Host "        K=$k"
            $m = computeJ "GMM" "Manual" $dir_in $dir_out "gmm_d${d}_K${k}"
            $f = computePartGmmJ $dir_in $dir_out "gmm_d${d}_K${k}"
            $near = $comparer.AreGmmFullAndPartGradientsNear($m, $f, $defaultAbsoluteTolerance, $defaultRelativeTolerance)
            if ($near.Near) {
                Remove-Item $f
                Rename-Item $m "${dir_out}gmm_d${d}_K${k}.txt"
                Write-Host "Maximum absolute difference: $($near.MaxAbsDifference)"
                Write-Host "Maximum relative difference: $($near.MaxRelDifference)"
            } else {
                $msg = "Inconsistent results between manual and finite on gmm_d${d}_K${k}`n" + $near.Error
                Write-Error $msg
                $errors.Add($msg)
                Rename-Item $m "${dir_out}gmm_d${d}_K${k}.txt"
            }
            if ($near.MaxAbsDifference -gt $maxAbsDiff) {
                $maxAbsDiff = $near.MaxAbsDifference
            }
            if ($near.MaxRelDifference -gt $maxRelDiff) {
                $maxRelDiff = $near.MaxRelDifference
            }
		}
	}
}

# Manual BA
Write-Host "Manually computing BA jacobians"

$dir_out = "$outdir/ba/"
mkdir_p $dir_out

for ($n = $ba_min_n; $n -le $ba_max_n; $n++) {
	Write-Host "    $n"
    $m = computeJ "BA" "Manual" $ba_dir_in $dir_out "ba$n"
    $f = computeJ "BA" "Finite" $ba_dir_in $dir_out "ba$n"
    $near = $comparer.AreNumTextFilesNear($m, $f, $defaultAbsoluteTolerance, $defaultRelativeTolerance)
    if ($near.Near) {
        Remove-Item $f
        Rename-Item $m "${dir_out}ba$n.txt"
        Write-Host "Maximum absolute difference: $($near.MaxAbsDifference)"
        Write-Host "Maximum relative difference: $($near.MaxRelDifference)"
    } else {
        $msg = "Inconsistent results between manual and finite on ba$n`n" + $near.Error
        Write-Error $msg
        $errors.Add($msg)
    }
    if ($near.MaxAbsDifference -gt $maxAbsDiff) {
        $maxAbsDiff = $near.MaxAbsDifference
    }
    if ($near.MaxRelDifference -gt $maxRelDiff) {
        $maxRelDiff = $near.MaxRelDifference
    }
}

# Manual Hand
Write-Host "Manually computing Hand jacobians"

foreach ($type in @("simple", "complicated")) {
	foreach ($sz in $hand_sizes) {
		Write-Host "    ${type}_$sz"

		$dir_in = "$hand_dir_in${type}_$sz/"
		$dir_out = "$outdir/hand/${type}_$sz/"
		mkdir_p $dir_out

		for ($n = $hand_min_n; $n -le $hand_max_n; $n++) {
			Write-Host "      $n"
            if ($type -eq "simple") {
                $task = ""
            } else {
                $task = "-Complicated"
            }
            $m = computeJ "Hand${task}" "Manual" $dir_in $dir_out "hand$n"
            $f = computeJ "Hand${task}" "Finite" $dir_in $dir_out "hand$n"
            $near = $comparer.AreNumTextFilesNear($m, $f, $defaultAbsoluteTolerance, $defaultRelativeTolerance)
            if ($near.Near) {
                Remove-Item $f
                Rename-Item $m "${dir_out}hand$n.txt"
                Write-Host "Maximum absolute difference: $($near.MaxAbsDifference)"
                Write-Host "Maximum relative difference: $($near.MaxRelDifference)"
            } else {
                $msg = "Inconsistent results between manual and finite on hand$n`n" + $near.Error
                Write-Error $msg
                $errors.Add($msg)
            }
            if ($near.MaxAbsDifference -gt $maxAbsDiff) {
                $maxAbsDiff = $near.MaxAbsDifference
            }
            if ($near.MaxRelDifference -gt $maxRelDiff) {
                $maxRelDiff = $near.MaxRelDifference
            }
		}
	}
}

# Manual LSTM
Write-Host "Manually computing LSTM gradients"
$dir_out = "$outdir/lstm/"
mkdir_p $dir_out

foreach ($l in $lstm_l_vals) {
	Write-Host "    l=$l"
	foreach ($c in $lstm_c_vals) {
		Write-Host "      c=$c"
        $m = computeJ "LSTM" "Manual" $lstm_dir_in $dir_out "lstm_l${l}_c$c"
        $f = computeJ "LSTM" "Finite" $lstm_dir_in $dir_out "lstm_l${l}_c$c"
        $near = $comparer.AreNumTextFilesNear($m, $f, $defaultAbsoluteTolerance, $defaultRelativeTolerance)
        if ($near.Near) {
            Remove-Item $f
            Rename-Item $m "${dir_out}lstm_l${l}_c$c.txt"
            Write-Host "Maximum absolute difference: $($near.MaxAbsDifference)"
            Write-Host "Maximum relative difference: $($near.MaxRelDifference)"
        } else {
            $msg = "Inconsistent results between manual and finite on lstm_l${l}_c$c`n" + $near.Error
            Write-Error $msg
            $errors.Add($msg)
        }
        if ($near.MaxAbsDifference -gt $maxAbsDiff) {
            $maxAbsDiff = $near.MaxAbsDifference
        }
        if ($near.MaxRelDifference -gt $maxRelDiff) {
            $maxRelDiff = $near.MaxRelDifference
        }
	}
}


Write-Host "Maximum absolute difference between values produced by manual and by finite is`n$maxAbsDiff`n"
Write-Host "Maximum relative difference between values produced by manual and by finite is`n$maxRelDiff`n"

foreach($msg in $errors) {
    Write-Error $msg
}