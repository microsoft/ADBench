$buildtype = "Release"
[double]$defaultTolerance = 1.0e-2;
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
    #if ($objective.contains("complicated")) { $task = "$task-Complicated" }
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

function areNumbersNear($x, $y, [double]$tolerance) {
    $xd = $x -as [double]
    $yd = $y -as [double]
    # relative difference = |x - y| / max(|x|,|y|)
    $reldiff = [Math]::Abs($xd - $yd) / [Math]::Max([Math]::Abs($xd), [Math]::Abs($yd))
    if ($reldiff -gt $tolerance) {
        return $false, $reldiff, "Relative difference between the numbers $x and $y (parsed as $xd and $yd) is $reldiff, which is greater than the allowed tolerance($tolerance)"
    }
    return $true, $reldiff, ""
}

function areNumLinesNear([string]$line1, [string]$line2, [double]$tolerance) {
    $separators=(" ","`t")
    $split1 = $line1.Split($separators)
    $split2 = $line2.Split($separators)
    $maxRelDiff = 0.0
    if ($split1.count -ne $split2.count) {
        return $false, $maxRelDiff, "Lines have different numbers of elements"
    }
    if ($split1.count -eq 1) {
        return areNumbersNear $split1 $split2 $tolerance
    } else {
        for ($n = 0; $n -lt $split1.count; $n++) {
            $nthResult = areNumbersNear $split1[$n] $split2[$n] $tolerance
            if (!$nthResult[0]) {
                return $false, $nthResult[1], "Error in position $n - $($nthResult[2])"
            }
            if ($nthResult[1] -gt $maxRelDiff) {
                $maxRelDiff = $nthResult[1]
            }
        }
    }
    return $true, $maxRelDiff, ""
}

function areNumTextFilesNear([string]$path1, [string]$path2, [double]$tolerance) {
    $j1 = Get-Content $path1
    $j2 = Get-Content $path2
    $maxRelDiff = 0.0
    if ($j1.count -ne $j2.count) {
        return $false, $maxRelDiff, "Texts have different numbers of lines"
    }
    if ($j1.count -eq 1) {
        return areNumLinesNear $j1 $j2 $tolerance
    } else {
        for ($n = 0; $n -lt $j1.count; $n++) {
            $nthResult = areNumLinesNear $j1[$n] $j2[$n] $tolerance
            if (!$nthResult[0]) {
                return $false, $nthResult[1], "Error in line $n - $($nthResult[2])"
            }
            if ($nthResult[1] -gt $maxRelDiff) {
                $maxRelDiff = $nthResult[1]
            }
        }
    }
    return $true, $maxRelDiff, ""
}

function areGmmFullAndPartGradientsNear([string]$path1, [string[]]$paths2, [double]$tolerance) {
    $j1 = Get-Content $path1
    $positions = Get-Content $paths2[0]
    $parts = @((Get-Content $paths2[1]), (Get-Content $paths2[2]), (Get-Content $paths2[3]))
    $maxRelDiff = 0.0
    for($i = 0; $i -lt 3; $i++) {
        $shift = $positions[$i] -as [int]
        for ($n = 0; $n -lt $parts[$i].count; $n++) {
            $nthResult = areNumbersNear $j1[$shift + $n] $parts[$i][$n] $tolerance
            if (!$nthResult[0]) {
                return $false, $nthResult[1], "Error in position $($shift + $n) - $($nthResult[2])"
            }
            if ($nthResult[1] -gt $maxRelDiff) {
                $maxRelDiff = $nthResult[1]
            }
        }
    }
    return $true, $maxRelDiff, ""
}

# Get source dir
$dir = Split-Path ($MyInvocation.MyCommand.Path)
$dir = Split-Path $dir

Write-Host "Root Directory: $dir"

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
[array]$gmm_sizes = @("1k") #, "10k", "2.5M")
[array]$hand_sizes = @("small", "big")
[int]$ba_min_n = 1
[int]$ba_max_n = 1 #20
[int]$hand_min_n = 1
[int]$hand_max_n = 1 #12
[array]$lstm_l_vals = @(2, 4)
[array]$lstm_c_vals = @(1024, 4096)
$gmm_d_vals = @(2, 10)#, 20, 32, 64)
$gmm_k_vals = @(5, 10)#, 25, 50, 100, 200)

$errors = New-Object Collections.Generic.List[string]
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
            $near = areGmmFullAndPartGradientsNear $m $f $defaultTolerance
            if ($near[0]) {
                Remove-Item $f
                Rename-Item $m "${dir_out}gmm_d${d}_K${k}.txt"
                Write-Host "Maximum relative difference: $($near[1])"
            } else {
                $msg = "Inconsistent results between manual and finite on gmm_d${d}_K${k}`n" + $near[2]
                Write-Error $msg
                $errors.Add($msg)
                Rename-Item $m "${dir_out}gmm_d${d}_K${k}.txt"
            }
            if ($near[1] -gt $maxRelDiff) {
                $maxRelDiff = $near[1]
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
    $near = areNumTextFilesNear $m $f $defaultTolerance
    if ($near[0]) {
        Remove-Item $f
        Rename-Item $m "${dir_out}ba$n.txt"
        Write-Host "Maximum relative difference: $($near[1])"
    } else {
        $msg = "Inconsistent results between manual and finite on ba$n`n" + $near[2]
        Write-Error $msg
        $errors.Add($msg)
    }
    if ($near[1] -gt $maxRelDiff) {
        $maxRelDiff = $near[1]
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
            $near = areNumTextFilesNear $m $f $defaultTolerance
            if ($near[0]) {
                Remove-Item $f
                Rename-Item $m "${dir_out}hand$n.txt"
                Write-Host "Maximum relative difference: $($near[1])"
            } else {
                $msg = "Inconsistent results between manual and finite on hand$n`n" + $near[2]
                Write-Error $msg
                $errors.Add($msg)
            }
            if ($near[1] -gt $maxRelDiff) {
                $maxRelDiff = $near[1]
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
        $near = areNumTextFilesNear $m $f $defaultTolerance
        if ($near[0]) {
            Remove-Item $f
            Rename-Item $m "${dir_out}lstm_l${l}_c$c.txt"
            Write-Host "Maximum relative difference: $($near[1])"
        } else {
            $msg = "Inconsistent results between manual and finite on lstm_l${l}_c$c`n" + $near[2]
            Write-Error $msg
            $errors.Add($msg)
        }
        if ($near[1] -gt $maxRelDiff) {
            $maxRelDiff = $near[1]
        }
	}
}

Write-Host "Maximum relative difference between values produced by manual and by finite is`n$maxRelDiff`n"

foreach($msg in $errors) {
    Write-Error $msg
}