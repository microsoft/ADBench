<#

.SYNOPSIS
This is a PowerShell script to run all autodiff benchmarking tests.

.DESCRIPTION
This script loops through each of a set of tools (defined using the Tool class) and runs a set of test functions on each of them.

.EXAMPLE
./run-all.ps1 -buildtype "Release" -minimum_measurable_time 0.5 -nruns_f 10 -nruns_J 10 -time_limit 180 -timeout 600 -tmpdir "C:/path/to/tmp/" -tools (echo Finite Manual Julia) -gmm_d_vals_param @(2,5,10,64)

This will:
- run only release builds
- loop measured function while total calculation time is less than 0.5 seconds
- aim to run 10 tests of each function, and 10 tests of the derivative of each function
- stop (having completed a whole number of tests) at any point after 180 seconds
- allow each program a maximum of 600 seconds to run all tests
- output results to "C:/path/to/tmp/"
- not repeat any tests for which there already exist a results file
- run only Finite, Manual, and Julia
- try GMM d values of 2, 5, 10, 64

.NOTES
See below for adding new tools or tests.

.LINK
https://github.com/awf/ADBench


#>

param(# Which build to test.
      # Builds should leave a script file 'cmake-vars-$buildtype.ps1' in the ADBench directory.
      # which sets $bindir to the build directory,
      # And if only some D,K are valid for GMM, sets $gmm_d_vals, and $gmm_k_vals
      [string]$buildtype="Release",

      # Estimated time of accurate result achievement.
      # A runner cyclically reruns measured function until total time becomes more than that value.
      # Supported only by the benchmark runner-based tools
      # (those with ToolType cpp, dotnet, julia, or python).
      [double]$minimum_measurable_time = 0.5,

      # Maximum number of times to run the function for timing
      [int]$nruns_f=10,

      # Maximum number of times to run the jacobian for timing
      [int]$nruns_J=10,

      # How many seconds to wait before we believe we have accurate timings
      [double]$time_limit=10,

      # Kill the test after this many seconds
      [double]$timeout=600,

      # Kill the test if it consumes more than this many gigabytes of RAM.
      [double]$max_memory_amount_in_gb=[double]::PositiveInfinity,

      # Where to store the ouput, defaults to tmp/ in the project root
      [string]$tmpdir="",

      # Repeat tests, even if output file exists
      [switch]$repeat,

      # Repeat only failed tests
      [switch]$repeat_failures,

      # List of tools to run
      [string[]]$tools=@(),

      # Don't delete produced jacobians even if they're accurate
      [switch]$keep_correct_jacobians,

      # GMM D values to try.  Must be a subset of the list of
      # compiled values in ADBench/cmake-vars-$buildtype.ps1
      [int[]]$gmm_d_vals_param,

      # GMM K values to run.  As above.
      [int[]]$gmm_k_vals_param,

      # GMM sizes to try. Must be a subset of @("1k", "10k", "2.5M")
      # 2.5M currently is not supported
      [string[]]$gmm_sizes = @("1k", "10k"),

      # Hand problem sizes to try. Must be a subset of @("small", "big")
      [string[]]$hand_sizes = @("small", "big"),

      # Number of the first BA problem to try. Must be between 1 and ba_max_n
      [int]$ba_min_n = 1,

      # Number of the last BA problem to try. Must be between ba_min_n and 20
      [int]$ba_max_n = 5,

      # Number of the first Hand problem to try. Must be between 1 and hand_max_n
      [int]$hand_min_n = 1,

      # Number of the last Hand problem to try. Must be between hand_min_n and 12
      [int]$hand_max_n = 5,

      # Numbers of layers in LSTM to try. Must be a subset of @(2, 4)
      [int[]]$lstm_l_vals = @(2, 4),

      # Sequence lengths in LSTM to try. Must be a subset of @(1024, 4096)
      [int[]]$lstm_c_vals = @(1024, 4096)
      )

# Sort array parameters define test sizes ascending
function sort_size_parameters() {
    $script:gmm_d_vals = $script:gmm_d_vals | Sort-Object
    $script:gmm_k_vals = $script:gmm_k_vals | Sort-Object
    $script:lstm_l_vals = $script:lstm_l_vals | Sort-Object
    $script:lstm_c_vals = $script:lstm_c_vals | Sort-Object
}

# Assert function
function assert ($expr) {
    if (!(& $expr @args)) {
        throw "Assertion failed [$expr]"
    }
}

# A global list of non-fatal errors to be printed at the end,
# and, optionally, affect the script's exit code
$non_fatal_errors=[System.Collections.Generic.List[string]]::new()

# Stores a non-fatal error in the global list and prints it on screen
function Report-NonFatalError([string]$message) {
    $non_fatal_errors.Add($message)
    Write-Warning $message
}

# Stores a non-fatal error in the global list without printing it on screen
function Store-NonFatalError([string]$message) {
    $non_fatal_errors.Add($message)
}

function Show-NonFatalErrors() {
    foreach ($message in $non_fatal_errors) {
        Write-Warning $message
    }
}

function Get-NonFatalErrorsHappened() {
    return $non_fatal_errors.Count -gt 0
}

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

# Type of run command function returning value
enum RunCommandStatus { Finished; Timeout; OutOfMemory }

# Run command and (reliably) get output
function run_command ($indent, $outfile, $timeout, $cmd) {
    write-host "Run [$cmd $args]"

    $status = [RunCommandStatus]::Finished

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

    $OOMCheckingInterval = 500      # milliseconds
    while (-not $Process.WaitForExit($OOMCheckingInterval)) {
        $Process.Refresh()
        if (-not $Process.HasExited) {
            $mem = 0
            try {
                $mem = $Process.PeakPagedMemorySize64
            } catch {
                # nothing to do because the process can exit by itself
            }

            $runTime = ((Get-Date) - $Process.StartTime).Duration().TotalSeconds

            if ($runTime -ge $timeout) {
                $Process.Kill()
                Write-Host "${indent}Killed after $timeout seconds"
                Store-NonFatalError "Process killed after $timeout seconds`n[$cmd $args]"
                create_timeout_file $outfile $timeout

                $status = [RunCommandStatus]::Timeout
                break
            } elseif ($mem -ge $max_memory_amount_in_bytes) {
                $Process.Kill()
                $mem = [math]::round($mem / (1024 * 1024 * 1024), 2)
                Write-Host "${indent}Killed due to consuming $mem GB of operating memory"
                Store-NonFatalError "Process killed due to consuming $mem GB of operating memory`n[$cmd $args]"

                $status = [RunCommandStatus]::OutOfMemory
                break
            }
        }
    }

    $stdout = $Process.StandardOutput.ReadToEnd().Trim().Replace("`n", "`n${indent}stdout> ")
    $stderr = $Process.StandardError.ReadToEnd().Trim().Replace("`n", "`n${indent}stderr> ")
    $allOutput = "${indent}stdout> " + $stdout + "`n${indent}stderr> " + $stderr
    Write-Host "$allOutput"

    return $status
}

# Create result time file with timeout content
function create_timeout_file($outfile, $timeout) {
    $result = "inf inf`ntf tJ`nFile generated by run-all.ps1 upon $timeout second timeout"
    Set-Content $outfile $result
}

# Get source dir
$dir = Split-Path ($MyInvocation.MyCommand.Path)
assert { $dir -match 'ADbench$' }
$dir = Split-Path $dir

Write-Host "Root Directory: $dir"

# Load cmake variables
$cmake_vars = "$dir/ADBench/cmake-vars-$buildtype.ps1"
if (!(Test-Path $cmake_vars)) {
   throw "No cmake-vars file found at $cmake_vars. Remember to run cmake before running this script, and/or pass the -buildtype param."
}
. $cmake_vars

Add-Type -Path "$bindir/src/dotnet/utils/JacobianComparisonLib/JacobianComparisonLib.dll"

function New-JacobianComparison(
    [double] $tolerance
){
    return [JacobianComparisonLib.JacobianComparison]::new($tolerance)
}

# $gmm_d_vals and $gmm_k_vals are configured using CMake because some
# tools (i.e. the tools that use matrices whose size is known at
# compile time) have one executable per matrix size.  I added a way to
# override them here.  If you are using the tools with one executable
# per matrix size then naturally these values should be a subset of
# the ones CMake built with.
if ($gmm_d_vals_param) { $gmm_d_vals = $gmm_d_vals_param }
if ($gmm_k_vals_param) { $gmm_k_vals = $gmm_k_vals_param }

# as far as the script checks guaranteed timeouts, we need array parameters, that
# define test sizes, to be sorted ascending
sort_size_parameters

# convert max memory amount parameter to bytes
$max_memory_amount_in_bytes = $max_memory_amount_in_gb * 1024 * 1024 * 1024

# Set tmpdir default
if (!$tmpdir) { $tmpdir = "$dir/tmp" }
$tmpdir += "/$buildtype"

$datadir = "$dir/data"

Write-Host "Build Type: $buildtype, output to $tmpdir`n"

enum ToolType
{
    bin
    cpp
    dotnet
    julia
    julia_tool
    matlab
    py
    pybat
    python
}

[flags()] enum ObjectiveType
{
    GMM = 1
    BA = 2
    Hand = 4
    LSTM = 8
}

enum RunTestStatus { Success; Timeout; Skipped; IncorrectResults; OutOfMemory }   # run benchmark statuses

# Custom Tool class
Class Tool {
    [string]$name
    [ToolType]$type
    [ObjectiveType]$objectives
    [bool]$gmm_both
    [bool]$gmm_use_defs
    [bool]$check_results
    [double]$result_check_tolerance

    # Static constants
    static [string]$golden_tool_name = "" # Name of the tool that is known to produce correct results, other tools can be checked against.
    static [string]$gmm_dir_in = "$datadir/gmm/"
    static [string]$ba_dir_in = "$datadir/ba/"
    static [string]$hand_dir_in = "$datadir/hand/"
    static [string]$lstm_dir_in = "$datadir/lstm/"

    # Constructor
    Tool ([string]$name, [ToolType]$type, [ObjectiveType]$objectives, [bool]$check_results, [double]$result_check_tolerance) {
        <#
        .SYNOPSIS
        Create a new Tool object to be run

        .EXAMPLE
        [Tool]::new("Finite", "bin", [ObjectiveType] "GMM, BA, Hand, LSTM", $false, 0.0)
        This will create a Tool:
        - called "Finite"
        - run from binary executables
        - runs all four tests
        - does not do GMM in separate FULL and SPLIT modes
        - doesn't require separate executables for different GMM sizes
        - does not check the correctness of the computed jacobians

        .NOTES
        $objectives is an enumerable variable,
        where each flag determines whether to run a certain objective:
        GMM, BA, HAND, LSTM

        #>

        $this.name = $name
        $this.type = $type
        $this.objectives = $objectives
        $this.check_results = $check_results
        $this.result_check_tolerance = $result_check_tolerance
        $this.gmm_both = $false
        $this.gmm_use_defs = $false
    }

    Tool ([string]$name, [ToolType]$type, [ObjectiveType]$objectives, [bool]$check_results, [double]$result_check_tolerance, [bool]$gmm_both, [bool]$gmm_use_defs) {
        <#
        .SYNOPSIS
        Create a new Tool object to be run

        .EXAMPLE
        [Tool]::new("Finite", "bin", [ObjectiveType] "GMM, BA, Hand, LSTM", $false, 0.0, $false, $false)
        This will create a Tool:
        - called "Finite"
        - run from binary executables
        - runs all four tests
        - does not do GMM in separate FULL and SPLIT modes
        - doesn't require separate executables for different GMM sizes
        - does not check the correctness of the computed jacobians

        .NOTES
        $objectives is an enumerable variable,
        where each flag determines whether to run a certain objective:
        GMM, BA, HAND, LSTM

        #>

        $this.name = $name
        $this.type = $type
        $this.objectives = $objectives
        $this.check_results = $check_results
        $this.result_check_tolerance = $result_check_tolerance
        $this.gmm_both = $gmm_both
        $this.gmm_use_defs = $gmm_use_defs
    }

    # Run all tests for this tool
    [void] runall () {
        Write-Host $this.name
        if ($this.objectives.HasFlag([ObjectiveType]::GMM)) { $this.testgmm() }
        if ($this.objectives.HasFlag([ObjectiveType]::BA)) { $this.testba() }
        if ($this.objectives.HasFlag([ObjectiveType]::Hand)) { $this.testhand() }
        if ($this.objectives.HasFlag([ObjectiveType]::LSTM)) { $this.testlstm() }
    }

    # Run a single test
    [RunTestStatus] run ([string]$objective, [string]$dir_in, [string]$dir_out, [string]$fn) {
        $out_name_postfix = $this.get_out_name_postfix($objective)
        $output_file = $this.get_time_output_file_name($dir_out, $fn, $out_name_postfix)

        if (!$script:repeat -and (Test-Path $output_file)) {
            if ($script:repeat_failures) {
                $test_failed = Select-String -quiet '^inf inf$' $output_file
                if (!$test_failed) {
                    Write-Host "          Skipped test (already completed, and wasn't a fail)"
                    return [RunTestStatus]::Skipped
                }
            } else {
                Write-Host "          Skipped test (already completed)"
                return [RunTestStatus]::Skipped
            }
        }

        $cmd = ""
        $cmdargs = @($dir_in, $dir_out, $fn, $script:nruns_f, $script:nruns_J, $script:time_limit)
        if ($this.type -eq [ToolType]::bin) {
            $cmd = "$script:bindir/tools/$($this.name)/Tools-$($this.name)-$objective.exe"
        } elseif ($this.type -eq [ToolType]::cpp) {
            $cmd = "$script:bindir/src/cpp/runner/CppRunner.exe"
            $dir_name = $this.name.ToLowerInvariant()[0] + $this.name.Substring(1)
            $module_path = "$script:bindir/src/cpp/modules/$($dir_name)/$($this.name).dll"
            $task = $objective.Split("-")[0]
            if ($objective.contains("complicated")) { $task = "$task-Complicated" }
            $cmdargs = @("$task $module_path $dir_in$fn.txt $dir_out $script:minimum_measurable_time $script:nruns_f $script:nruns_J $script:time_limit")
        } elseif ($this.type -eq [ToolType]::python) {
            $objective = $objective.ToUpper()
            $test_type = $objective.Split("-")[0]
            if ($objective.contains("COMPLICATED")) { $test_type = "$($test_type)-COMPLICATED" }
            $suffix = $test_type
            if ($test_type.contains("HAND")) { $suffix = "Hand" }
            $cmd = $script:pythonexec
            $module_loader = @("$script:dir/src/python/runner/main.py")
            $module_path = @("$script:dir/src/python/modules/$($this.name)/$($this.name)$suffix.py")
            $cmdargs = @("$module_loader $test_type $module_path $dir_in$fn.txt $dir_out $script:minimum_measurable_time $script:nruns_f $script:nruns_J $script:time_limit")
        } elseif ($this.type -eq [ToolType]::dotnet) {
            $cmd = "dotnet"
            $module_path = "$script:bindir/src/dotnet/modules/$($this.name)/$($this.name).dll"
            $task = $objective.Split("-")[0]
            if ($objective.contains("complicated")) { $task = "$task-Complicated" }
            $cmdargs = @("$script:bindir/src/dotnet/runner/DotnetRunner.dll $task $module_path $dir_in$fn.txt $dir_out $script:minimum_measurable_time $script:nruns_f $script:nruns_J $script:time_limit")
        } elseif ($this.type -eq [ToolType]::py -or $this.type -eq [ToolType]::pybat) {
            $objective = $objective.ToLower().Replace("-", "_")
            if ($this.type -eq "py") { $cmd = $script:pythonexec }
            elseif ($this.type -eq "pybat") { $cmd = "$script:dir/tools/$($this.name)/run.bat" }
            $cmdargs = @("$script:dir/tools/$($this.name)/$($this.name)_$objective.py") + $cmdargs
        } elseif ($this.type -eq [ToolType]::julia) {
            $objective = $objective.ToLower().Replace("-", "_")
            $cmd = "julia"
            $task = $objective.Split("_")[0]
            $module_path = "$script:dir/src/julia/modules/$($this.name)/$($this.name)$($task.ToUpperInvariant()).jl"
            if ($objective.contains("complicated")) { $task = "$task-Complicated" }
            $cmdargs = @("$task $module_path $dir_in$fn.txt $dir_out $script:minimum_measurable_time $script:nruns_f $script:nruns_J $script:time_limit")
            $cmdargs = @("--project=$script:dir", "--optimize=3", "$script:dir/src/julia/runner/Runner.jl") + $cmdargs
        } elseif ($this.type -eq [ToolType]::julia_tool) {
            $objective = $objective.ToLower().Replace("-", "_")
            $cmd = "julia"
            $cmdargs = @("--project=$script:dir", "$script:dir/tools/$($this.name)/${objective}_F.jl") + $cmdargs
        } elseif ($this.type -eq [ToolType]::matlab) {
            $objective = $objective.ToLower().Replace("-", "_")
            $cmd = "matlab"
            $cmdargs = @("-wait", "-nosplash", "-nodesktop", "-r", "cd '$script:dir/tools/$($this.name)/'; addpath('$script:bindir/tools/$($this.name)/'); $($this.name)_$objective $cmdargs; quit")
        }

        $run_command_status = run_command "          " $output_file $script:timeout $cmd @cmdargs
        $status = [RunTestStatus]::Success

        if (!(test-path $output_file)) {
            Report-NonFatalError "Command ran, but did not produce output file [$output_file]"
        }

        if ($this.check_results -and (![string]::IsNullOrEmpty([Tool]::golden_tool_name))) {
            $is_correct = $this.check_correctness($dir_out, $out_name_postfix, $fn)
            if (-not $is_correct) {
                $status = [RunTestStatus]::IncorrectResults
            }
        }

        if ($run_command_status -eq [RunCommandStatus]::Timeout) {
            $status = [RunTestStatus]::Timeout
        }

        if ($run_command_status -eq [RunCommandStatus]::OutOfMemory) {
            $status = [RunTestStatus]::OutOfMemory
        }

        return $status
    }

    # Get postfix for tool output file name
    [string] get_out_name_postfix([string]$objective) {
        $postfix = $this.name

        if ($objective.contains("Eigen")) {
            $postfix = "$($this.name)_Eigen"
        } elseif ($objective.endswith("SPLIT")) {
            $postfix = "$($this.name)_split"
        }

        return $postfix
    }

    [string] get_time_output_file_name([string]$dir_out, [string]$fn, [string]$out_name_postfix) {
        return "${dir_out}${fn}_times_${out_name_postfix}.txt"
    }

    # Check correctness of the tool run results creating respective correctness file
    [bool] check_correctness([string]$dir_out, [string]$out_name_postfix, [string]$fn) {
        $current_jacobian_path = "${dir_out}${fn}_J_${out_name_postfix}.txt"
        $golden_jacobian_path = "${dir_out}../$([Tool]::golden_tool_name)/${fn}_J_$([Tool]::golden_tool_name).txt"
        $comparison = New-JacobianComparison $this.result_check_tolerance
        $comparison.CompareFiles($current_jacobian_path, $golden_jacobian_path)
        $comparison.ToJsonString() | Out-File "${dir_out}${fn}_correctness_${out_name_postfix}.txt" -encoding ASCII
        if ($comparison.ViolationsHappened()) {
            Report-NonFatalError "Discrepancies with the correct jacobian found. See ${dir_out}${fn}_correctness_${out_name_postfix}.txt for details."
            return $false
        } else {
            if (-not $script:keep_correct_jacobians) {
                $current_objective_path = "${dir_out}${fn}_F_${out_name_postfix}.txt"
                if (Test-Path $current_objective_path) { Remove-Item $current_objective_path }
                if (Test-Path $current_jacobian_path) { Remove-Item $current_jacobian_path }
            }
        }

        return $true
    }

    # Perform actions in case of guaranteed timeout (e.g. create time file with timeout content)
    [void] perform_guaranteed_timeout_actions([string]$run_obj, [string]$dir_out, [string]$fn) {
        Store-NonFatalError "Test didn't run due to guaranteed timeout`nObjective: $run_obj`nTest file name: $fn"
        $postfix = $this.get_out_name_postfix($run_obj)
        $time_file_name = $this.get_time_output_file_name($dir_out, $fn, $postfix)
        create_timeout_file $time_file_name $script:timeout

        # this is made for the result consistency, because in case of timeout
        # correctness checking is performed
        $this.check_correctness($dir_out, $postfix, $fn)
    }

    # Perform actions in case of guaranteed out of memory
    [void] perform_guaranteed_oom_actions([string]$run_obj, [string]$dir_out, [string]$fn) {
        Store-NonFatalError "Test didn't run due to guaranteed out of memory`nObjective: $run_obj`nTest file name: $fn"

        # this is made for the result consistency, because in case of out of memory
        # correctness checking is performed
        $postfix = $this.get_out_name_postfix($run_obj)
        $this.check_correctness($dir_out, $postfix, $fn)
    }

    # Run all gmm tests for this tool
    [void] testgmm () {
        if ($this.gmm_both) { $types = @("-FULL", "-SPLIT") }
        else { $types = @("") }

        foreach ($type in $types) {
            Write-Host "  GMM$type"

            foreach ($sz in $script:gmm_sizes) {
                Write-Host "    $sz"

                $dir_in = "$([Tool]::gmm_dir_in)$sz/"
                $dir_out = "$script:tmpdir/gmm/$sz/$($this.name)/"
                mkdir_p $dir_out

                $first_timeout_k = $script:gmm_k_vals[-1] + 1
                $first_oom_k = $script:gmm_k_vals[-1] + 1
                foreach ($d in $script:gmm_d_vals) {
                    Write-Host "      d=$d"
                    foreach ($k in $script:gmm_k_vals) {
                        Write-Host "        K=$k"
                        $fn = "gmm_d${d}_K${k}"
                        $run_obj = "GMM$type"
                        if ($this.gmm_use_defs) { $run_obj += "-d$d-K$k" }

                        if ($k -ge $first_timeout_k) {
                            Write-Host "          Didn't run due to guaranteed timeout"
                            $this.perform_guaranteed_timeout_actions($run_obj, $dir_out, $fn)
                        } elseif ($k -ge $first_oom_k) {
                            Write-Host "          Didn't run due to guaranteed out of memory"
                            $this.perform_guaranteed_oom_actions($run_obj, $dir_out, $fn)
                        } else {
                            $status = $this.run($run_obj, $dir_in, $dir_out, $fn)
                            if ($status -eq [RunTestStatus]::Timeout) {
                                $first_timeout_k = $k
                            } elseif ($status -eq [RunTestStatus]::OutOfMemory) {
                                $first_oom_k = $k
                            }
                        }
                    }
                }
            }
        }
    }

    # Run all BA tests for this tool
    [void] testba () {
        $dir_out = "$script:tmpdir/ba/$($this.name)/"
        if (!(Test-Path $dir_out)) { mkdir_p $dir_out }

        Write-Host "  BA"

        $status = [RunTestStatus]::Success
        for ($n = $script:ba_min_n; $n -le $script:ba_max_n; $n++) {
            $fn = (Get-ChildItem -Path $([Tool]::ba_dir_in) -Filter "ba${n}_*")[0].BaseName
            Write-Host "    $n"

            if ($status -eq [RunTestStatus]::Timeout) {
                Write-Host "      Didn't run due to guaranteed timeout"
                $this.perform_guaranteed_timeout_actions("BA", $dir_out, $fn)
            } elseif ($status -eq [RunTestStatus]::OutOfMemory) {
                Write-Host "      Didn't run due to guaranteed out of memory"
                $this.perform_guaranteed_oom_actions("BA", $dir_out, $fn)
            } else {
                $status = $this.run("BA", [Tool]::ba_dir_in, $dir_out, $fn)
            }
        }
    }

    # Run all Hand tests for this tool
    [void] testhand () {
        Write-Host "  Hand"

        foreach ($type in @("simple", "complicated")) {
            foreach ($sz in $script:hand_sizes) {
                Write-Host "    ${type}_$sz"

                $dir_in = "$([Tool]::hand_dir_in)${type}_$sz/"
                $dir_out = "$script:tmpdir/hand/${type}_$sz/$($this.name)/"
                mkdir_p $dir_out
                $run_obj = "Hand-${type}"

                $status = [RunTestStatus]::Success
                for ($n = $script:hand_min_n; $n -le $script:hand_max_n; $n++) {
                    $fn = (Get-ChildItem -Path $dir_in -Filter "hand${n}_*")[0].BaseName
                    Write-Host "      $n"

                    if ($status -eq [RunTestStatus]::Timeout) {
                        Write-Host "        Didn't run due to guaranteed timeout"
                        $this.perform_guaranteed_timeout_actions($run_obj, $dir_out, $fn)
                    } elseif ($status -eq [RunTestStatus]::OutOfMemory) {
                        Write-Host "      Didn't run due to guaranteed out of memory"
                        $this.perform_guaranteed_oom_actions($run_obj, $dir_out, $fn)
                    } else {
                        $status = $this.run($run_obj, $dir_in, $dir_out, $fn)
                    }
                }
            }
        }
    }

    [void] testlstm () {
        Write-Host "  LSTM"
        $dir_out = "$script:tmpdir/lstm/$($this.name)/"
        mkdir_p $dir_out

        $first_timeout_c = $script:lstm_c_vals[-1] + 1
        $first_oom_c = $script:lstm_c_vals[-1] + 1
        foreach ($l in $script:lstm_l_vals) {
            Write-Host "    l=$l"

            foreach ($c in $script:lstm_c_vals) {
                Write-Host "      c=$c"

                if ($c -ge $first_timeout_c) {
                    Write-Host "        Didn't run due to guaranteed timeout"
                    $this.perform_guaranteed_timeout_actions("LSTM", $dir_out, "lstm_l${l}_c$c")
                }elseif ($c -ge $first_oom_c) {
                    Write-Host "        Didn't run due to guaranteed out of memory"
                    $this.perform_guaranteed_oom_actions("LSTM", $dir_out, "lstm_l${l}_c$c")
                } else {
                    $status = $this.run("LSTM", [Tool]::lstm_dir_in, $dir_out, "lstm_l${l}_c$c")
                    if ($status -eq [RunTestStatus]::Timeout) {
                        $first_timeout_c = $c
                    } elseif ($status -eq [RunTestStatus]::OutOfMemory) {
                        $first_oom_c = $c
                    }
                }
            }
        }
    }
}


[Tool]::golden_tool_name = "Manual"
$default_tolerance = 1e-8
# Full list of tool_descriptors
# Name
# runtype
# GMM, BA, HAND, LSTM
# Compare jacobian to those produced by the golden tool?
# Comparison tolerance (ignored, when previous is $false)
# Separate Full|Split?
# Separate GMM sizes?
$tool_descriptors = @(
    #[Tool]::new("Adept", "bin", [ObjectiveType] "GMM, BA, Hand", $false, 0.0, $true, $false)
    #[Tool]::new("ADOLC", "bin", [ObjectiveType] "GMM, BA, Hand", $false, 0.0, $true, $false)
    #[Tool]::new("ADOLCEigen", "bin", [ObjectiveType] "Hand", $false, 0.0, $true, $false)
    #[Tool]::new("Ceres", "bin", [ObjectiveType] "GMM, BA, Hand", $false, 0.0, $false, $true)
    #[Tool]::new("CeresEigen", "bin", [ObjectiveType] "Hand", $false, 0.0, $false, $true)
    [Tool]::new("Finite", "cpp", [ObjectiveType] "GMM, BA, Hand, LSTM", $true, 1e-4)
    [Tool]::new("FiniteEigen", "cpp", [ObjectiveType] "Hand", $true, 1e-4)
    [Tool]::new("Manual", "cpp", [ObjectiveType] "GMM, BA, Hand, LSTM", $false, 0.0)
    [Tool]::new("ManualEigen", "cpp", [ObjectiveType] "GMM, BA, Hand, LSTM", $true, $default_tolerance)
    [Tool]::new("ManualEigenVector", "cpp", [ObjectiveType] "GMM", $true, $default_tolerance)
    [Tool]::new("DiffSharpModule", "dotnet", [ObjectiveType] "GMM, BA, Hand, LSTM", $true, $default_tolerance)
    [Tool]::new("Tapenade", "cpp", [ObjectiveType] "BA, LSTM, GMM, Hand", $true, $default_tolerance)
    [Tool]::new("PyTorch", "python", [ObjectiveType] "BA, LSTM, GMM, Hand", $true, 1e-7)
    [Tool]::new("PyTorchGPU", "python", [ObjectiveType] "BA, LSTM, GMM, Hand", $true, 1e-7)
    [Tool]::new("PyTorchVmap", "python", [ObjectiveType] "BA, Hand", $true, 1e-7)
    [Tool]::new("PyTorchVmapGPU", "python", [ObjectiveType] "BA, Hand", $true, 1e-7)
    [Tool]::new("TorchScript", "python", [ObjectiveType] "GMM", $true, 1e-7)
    [Tool]::new("Tensorflow", "python", [ObjectiveType] "BA, LSTM, GMM, Hand", $true, $default_tolerance)
    [Tool]::new("TensorflowGraph", "python", [ObjectiveType] "BA, LSTM, GMM, Hand", $true, $default_tolerance)
    [Tool]::new("FreeTensor", "python", [ObjectiveType] "BA, LSTM, GMM, Hand", $true, 1e-7)
    [Tool]::new("FreeTensorGPU", "python", [ObjectiveType] "BA, LSTM, GMM, Hand", $true, 1e-7)
    [Tool]::new("FreeTensorEnzyme", "python", [ObjectiveType] "BA, LSTM, GMM, Hand", $true, 1e-7)
    [Tool]::new("Autograd", "py", [ObjectiveType] "GMM, BA", $false, 0.0, $true, $false)
    [Tool]::new("Julia", "julia_tool", [ObjectiveType] "GMM, BA", $false, 0.0)
    [Tool]::new("Zygote", "julia", [ObjectiveType] "GMM, BA, Hand, LSTM", $true, $default_tolerance)
    #[Tool]::new("Theano", "pybat", [ObjectiveType] "GMM, BA, Hand", $false, 0.0)
    #[Tool]::new("MuPad", "matlab", 0, $false, 0.0)
    #[Tool]::new("ADiMat", "matlab", 0, $false, 0.0)
)

$golden_tool = $tool_descriptors | ? { $_.name -eq [Tool]::golden_tool_name }

if ($tools) {
    if ($golden_tool -and $tools.Contains([Tool]::golden_tool_name)) {
        write-host "User-specified tool $([Tool]::golden_tool_name))"
        $golden_tool.runall()
    }
    foreach($tool in $tools | Where-Object { $_ -ne [Tool]::golden_tool_name }) {
        write-host "User-specified tool $tool"
        $tool_descriptor = $tool_descriptors | ? { $_.name -eq $tool }
        if (!$tool_descriptor) {
            throw "Unknown tool [$tool]"
        }
        $tool_descriptor.runall()
    }
}
else {
    # Run all tests on each tool. If the golden tool is defined, tests on it run first.
    if ($golden_tool) {
        $golden_tool.runall()
    }
    foreach ($tool_descriptor in $tool_descriptors | Where-Object { $_.name -ne [Tool]::golden_tool_name }) {
        $tool_descriptor.runall()
    }
}

$exitcode = 0
if (Get-NonFatalErrorsHappened) {
    Write-Warning "Errors happened:`n"
    $exitcode = 8
    Show-NonFatalErrors
}

exit $exitcode
