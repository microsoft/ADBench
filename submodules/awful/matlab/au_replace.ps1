$awf_re = 'awf_(sparse|sparse_test|whist|whist|whist_test)\b'
$mlp_re = 'mlp_(' + 
 'ad_bundle_fun|' +
 'ad_bundle_fun_mex|' +
 'assert|' +
 'assert_equal|' +
 'ccode|' +
 'ccode_test|' +
 'coeff|' +
 'logsumexp|' +
 'prmat|' +
 'ransac|' +
 'ransac_demo|' +
 'ssd|' +
 'ssd|' +
 'ssd_test|' +
 'test_equal|' +
 'test_regexp|' +
 'test_test)\b'

dir -rec l:\ *.m | selex fullname | % { 
  $found = 0;
  $fn = $_;
  cat $fn | % { 
    if ($_ -match $awf_re -or $_ -match $mlp_re) {
      $found = 1;
    }
  }
  if ($found) {
    $new = "$fn.new"
    write-host "writing to $new"
    cat $fn | % { $_ -replace $awf_re,'au_$1' -replace $mlp_re,'au_$1' } | out-file -enc ascii $new
    grep au_ $new | % { write-host -foreg blue $_ }
  }
}

dir -rec l:\ *.m.new | selex fullname | % { $b = $_ -replace '.new$',''; mv -whatif $b "$b.bak"; mv -whatif $_ $b }
