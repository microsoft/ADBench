-- This test stanza is used only for standalone benchmarking.  The
-- ADBench benchmarking goes through gmm.cpp.  For this to work,
-- you'll need to manually construct Futhark versions of the datasets,
-- for example by compiling gmm_data.cpp and running
--
--    $ for f in ../../data/gmm/10k/*.txt; do ./gmm_data $f > $(basename $f | sed s/txt/in/); done
--
-- ==
-- entry: rev_gmm_objective
-- input @ gmm_d2_K5.in
-- input @ gmm_d2_K10.in
-- input @ gmm_d2_K25.in
-- input @ gmm_d2_K50.in
-- input @ gmm_d2_K100.in
-- input @ gmm_d2_K200.in
--
-- input @ gmm_d10_K5.in
-- input @ gmm_d10_K10.in
-- input @ gmm_d10_K25.in
-- input @ gmm_d10_K50.in
-- input @ gmm_d10_K100.in
-- input @ gmm_d10_K200.in
--
-- input @ gmm_d20_K5.in
-- input @ gmm_d20_K10.in
-- input @ gmm_d20_K25.in
-- input @ gmm_d20_K50.in
-- input @ gmm_d20_K100.in
-- input @ gmm_d20_K200.in
--
-- input @ gmm_d32_K5.in
-- input @ gmm_d32_K10.in
-- input @ gmm_d32_K25.in
-- input @ gmm_d32_K50.in
-- input @ gmm_d32_K100.in
-- input @ gmm_d32_K200.in
--
-- input @ gmm_d64_K5.in
-- input @ gmm_d64_K10.in
-- input @ gmm_d64_K25.in
-- input @ gmm_d64_K50.in
-- input @ gmm_d64_K100.in
-- input @ gmm_d64_K200.in

import "gmm_knossos"

entry gmm_objective [N] [D] [K] [triD]
                    (x : [N][D]f64)
                    (alphas : [K]f64) (means : [K][D]f64)
                    (qs : [K][D]f64) (icf : [K][triD]f64)
                    (wishart_gamma : f64) (wishart_m : i32)
                    : f64 =
  unsafe gmm_knossos_gmm_objective x alphas means qs icf (wishart_gamma, wishart_m)

entry rev_gmm_objective [N] [D] [K] [triD]
                        (x : [N][D]f64)
                        (alphas : [K]f64) (means : [K][D]f64)
                        (qs : [K][D]f64) (icf : [K][triD]f64)
                        (wishart_gamma : f64) (wishart_m : i32)
                        (d_r: f64)
                         : ([K]f64, [K][D]f64, [K][D]f64, [K][triD]f64) =
  let (_a,b,c,d,e, _) = unsafe rev_gmm_knossos_gmm_objective x alphas means qs icf (wishart_gamma, wishart_m) d_r
  in (b,c,d,e)
