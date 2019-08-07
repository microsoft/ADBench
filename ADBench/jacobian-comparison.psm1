Class ComparisonResult {
    [bool] $Near
    [double] $MaxAbsDifference
    [double] $MaxRelDifference
    [string] $Error

    ComparisonResult(){
        $this.Set($false, 0.0, 0.0)
    }

    ComparisonResult(
        [bool] $near,
        [double] $maxAbsDifference,
        [double] $maxRelDifference
    ){
        $this.Set($near, $maxAbsDifference, $maxRelDifference)
    }

    ComparisonResult(
        [bool] $near,
        [double] $maxAbsDifference,
        [double] $maxRelDifference,
        [string] $error
    ){
        $this.Set($near, $maxAbsDifference, $maxRelDifference, $error)
    }

    [void] Set(
        [bool] $near,
        [double] $maxAbsDifference,
        [double] $maxRelDifference
    ){
        $this.Set($near, $maxAbsDifference, $maxRelDifference, "")
    }

    [void] Set(
        [bool] $near,
        [double] $maxAbsDifference,
        [double] $maxRelDifference,
        [string] $error
    ){
        $this.Near = $near
        $this.MaxAbsDifference = $maxAbsDifference
        $this.MaxRelDifference = $maxRelDifference
        $this.Error = $error
    }
}

Class Comparer {
    [void] AreNumbersNear([string]$x, [string]$y, [double]$toleranceAbs, [double]$toleranceRel, [ComparisonResult]$result) {
        $xd = $x -as [double]
        $yd = $y -as [double]
        # relative difference = |x - y| / max(|x|,|y|)
        $absdiff = [Math]::Abs($xd - $yd)
        $reldiff = $absdiff / [Math]::Max([Math]::Abs($xd), [Math]::Abs($yd))
        if ($absdiff -gt $toleranceAbs -and $reldiff -gt $toleranceRel) {
            $result.Set($false, $absdiff, $reldiff,
                "Relative difference between the numbers $x and $y (parsed as $xd and $yd) is $reldiff, which is greater than the allowed tolerance($toleranceRel)`n" +
                "Absolute difference between the numbers $x and $y (parsed as $xd and $yd) is $absdiff, which is greater than the allowed tolerance($toleranceAbs)")
            return
        }
        $result.Set($true, $absdiff, $reldiff)
        return
    }
    
    [void] AreNumLinesNear([string]$line1, [string]$line2, [double]$toleranceAbs, [double]$toleranceRel, [ComparisonResult]$result) {
        $separators=(" ","`t")
        $split1 = $line1.Split($separators)
        $split2 = $line2.Split($separators)
        $maxAbsDiff = 0.0
        $maxRelDiff = 0.0
        $nthResult = [ComparisonResult]::new()
        if ($split1.count -ne $split2.count) {
            $result.Set($false, $maxAbsDiff, $maxRelDiff, "Lines have different numbers of elements")
            return
        }
        if ($split1.count -eq 1) {
            $this.AreNumbersNear($split1, $split2, $toleranceAbs, $toleranceRel, $result)
            return
        } else {
            for ($n = 0; $n -lt $split1.count; $n++) {
                $this.AreNumbersNear($split1[$n], $split2[$n], $toleranceAbs, $toleranceRel, $nthResult)
                if (!$nthResult.Near) {
                    $result.Set($false, $nthResult.MaxAbsDifference, $nthResult.MaxRelDifference, "Error in position $n - $($nthResult.Error)")
                    return
                }
                if ($nthResult.MaxAbsDifference -gt $maxAbsDiff) {
                    $maxAbsDiff = $nthResult.MaxAbsDifference
                }
                if ($nthResult.MaxRelDifference -gt $maxRelDiff) {
                    $maxRelDiff = $nthResult.MaxRelDifference
                }
            }
        }
        $result.Set($true, $maxAbsDiff, $maxRelDiff)
        return
    }
    
    [ComparisonResult] AreNumTextFilesNear([string]$path1, [string]$path2, [double]$toleranceAbs, [double]$toleranceRel) {
        $j1 = Get-Content $path1
        $j2 = Get-Content $path2
        $maxAbsDiff = 0.0
        $maxRelDiff = 0.0
        $nthResult = [ComparisonResult]::new()
        if ($j1.count -ne $j2.count) {
            return [ComparisonResult]::new($false, $maxAbsDiff, $maxRelDiff, "Texts have different numbers of lines")
        }
        if ($j1.count -eq 1) {
            $this.AreNumLinesNear($j1, $j2, $toleranceAbs, $toleranceRel, $nthResult)
            return $nthResult
        } else {
            for ($n = 0; $n -lt $j1.count; $n++) {
                $this.AreNumLinesNear($j1[$n], $j2[$n], $toleranceAbs, $toleranceRel, $nthResult)
                if (!$nthResult.Near) {
                    return [ComparisonResult]::new($false, $nthResult.MaxAbsDifference, $nthResult.MaxRelDifference, "Error in line $n - $($nthResult.Error)")
                }
                if ($nthResult.MaxAbsDifference -gt $maxAbsDiff) {
                    $maxAbsDiff = $nthResult.MaxAbsDifference
                }
                if ($nthResult.MaxRelDifference -gt $maxRelDiff) {
                    $maxRelDiff = $nthResult.MaxRelDifference
                }
            }
        }
        return [ComparisonResult]::new($true, $maxAbsDiff, $maxRelDiff)
    }
    
    [ComparisonResult] AreGmmFullAndPartGradientsNear([string]$path1, [string[]]$paths2, [double]$toleranceAbs, [double]$toleranceRel) {
        $j1 = Get-Content $path1
        $positions = Get-Content $paths2[0]
        $parts = @((Get-Content $paths2[1]), (Get-Content $paths2[2]), (Get-Content $paths2[3]))
        $maxAbsDiff = 0.0
        $maxRelDiff = 0.0
        $nthResult = [ComparisonResult]::new()
        for($i = 0; $i -lt 3; $i++) {
            $shift = $positions[$i] -as [int]
            for ($n = 0; $n -lt $parts[$i].count; $n++) {
                $this.AreNumbersNear($j1[$shift + $n], $parts[$i][$n], $toleranceAbs, $toleranceRel, $nthResult)
                if (!$nthResult.Near) {
                    return [ComparisonResult]::new($false, $nthResult.MaxAbsDifference, $nthResult.MaxRelDifference, "Error in position $($shift + $n) - $($nthResult.Error)")
                }
                if ($nthResult.MaxAbsDifference -gt $maxAbsDiff) {
                    $maxAbsDiff = $nthResult.MaxAbsDifference
                }
                if ($nthResult.MaxRelDifference -gt $maxRelDiff) {
                    $maxRelDiff = $nthResult.MaxRelDifference
                }
            }
        }
        return [ComparisonResult]::new($true, $maxAbsDiff, $maxRelDiff)
    }
}

function Get-Comparer() {
    return [Comparer]::new()
}

Export-ModuleMember -Function Get-Comparer