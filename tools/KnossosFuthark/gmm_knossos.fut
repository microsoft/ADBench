let build = tabulate
let exp = f64.exp
let log = f64.log
let sum = f64.sum
let to_float = r64
let neg (x: f64) = -x
let lgamma = f64.lgamma
let digamma = const 1f64 -- FIXME
let dotv xs ys = map2 (*) xs ys |> f64.sum
let mul_Mat_Vec xss ys = map (dotv ys) xss
let u_rand scale = scale
let constVec = replicate

let deltaVec 't (zero: t) (n: i32) i (v: t) : [n]t =
  tabulate n (\j -> if j == i then v else zero)

let delta 't (zero: t) (i: i32) (j: i32) (v: t) =
  if i == j then v else zero

let rev_mul_Mat_Vec [r][c] (M: [r][c]f64) (v: [c]f64) (dr: [r]f64): ([r][c]f64, [c]f64) =
  (map (\x -> map (*x) v) dr,
   map (\col -> f64.sum (map2 (*) col dr)) (transpose M))

let upper_tri_to_linear (D: i32) (v: [D][D]f64) =
  tabulate_2d D D (\i j -> j >= i)
  |> flatten
  |> zip (flatten v)
  |> filter (.2)
  |> map (.1)

type lm 'a 'b = a -> b
let gmm_knossos_tri (n: i32) : i32 = (n * (n - 1)) / 2

let exp_VecR [n] (v: [n]f64) : [n]f64 = build n (\i -> exp v[i])

let mul_R_VecR [n] (r: f64) (a: [n]f64) : [n]f64 =
  build n (\i -> r * a[i])

let mul_R_VecVecR [m] [n] (r: f64) (a: [m][n]f64) : [m][n]f64 =
  build m (\i -> mul_R_VecR r a[i])

let mul_VecR_VecR [n] (a: [n]f64) (b: [n]f64) : [n]f64 =
  build n (\i -> a[i] * b[i])

let sub_VecR_VecR [n] (a: [n]f64) (b: [n]f64) : [n]f64 =
  build n (\i -> a[i] - b[i])

-- (edef dotv Float (a : Vec n Float, b : Vec n Float))

-- (edef
--  D$dotv
--  (LM (Tuple (Vec n Float), (Vec n Float)) Float)
--  (a : Vec n Float, b : Vec n Float))

-- (edef
--  R$dotv
--  (LM Float (Tuple (Vec n Float), (Vec n Float)))
--  (a : Vec n Float, b : Vec n Float))

let fwd_dotv [n] (a: [n]f64) (b: [n]f64) (da: [n]f64)
                 (db: [n]f64) : f64 =
  dotv a db + dotv da b

let rev_dotv [n] (a: [n]f64) (b: [n]f64) (dr: f64) : ([n]f64,
                                                      [n]f64) =
  (mul_R_VecR dr b, mul_R_VecR dr a)

let dotvv [m] [n] (a: [m][n]f64) (b: [m][n]f64) : f64 =
  reduce (+) 0.0 (tabulate m (\i -> dotv a[i] b[i]))

let sqnorm [n] (v: [n]f64) : f64 = dotv v v

-- (edef
--  mul$Mat$Vec
--  (Vec m Float)
--  (a : Vec m (Vec n Float), b : Vec n Float))

-- (edef
--  D$mul$Mat$Vec
--  (LM (Tuple (Vec m (Vec n Float)), (Vec n Float)) (Vec m Float))
--  (a : Vec m (Vec n Float), b : Vec n Float))

-- (edef
--  R$mul$Mat$Vec
--  (LM (Vec m Float) (Tuple (Vec m (Vec n Float)), (Vec n Float)))
--  (a : Vec m (Vec n Float), b : Vec n Float))

let fwd_mul_Mat_Vec [m] [n] (M: [m][n]f64) (v: [n]f64)
                            (dM: [m][n]f64) (dv: [n]f64) : [m]f64 =
  map2 (+) (mul_Mat_Vec dM v) (mul_Mat_Vec M dv)

-- (edef
--  rev$mul$Mat$Vec
--  (Tuple (Vec m (Vec n Float)), (Vec n Float))
--  (a : Vec m (Vec n Float), b : Vec n Float, c : Vec m Float))

let gmm_knossos_makeQ [D] [triD] (q: [D]f64)
                                 (l: [triD]f64) : [D][D]f64 =
  build D
        (\i ->
            build D
                  (\j ->
                      if i < j
                      then 0.0
                      else if i == j
                           then exp q[i]
                           else l[(((gmm_knossos_tri D) - (gmm_knossos_tri (D-j))) + ((i - j) - 1))]))

let logsumexp [n] (v: [n]f64) : f64 = log (sum (exp_VecR v))

let log_gamma_distrib (a: f64) (p: i32) : f64 =
  0.28618247146235004 * to_float (p * (p - 1)) + reduce (+)
                                                        0.0
                                                        (tabulate p
                                                                  (\j ->
                                                                      lgamma (a - (0.5 * to_float j))))

let log_wishart_prior [p] [tri_p] (wishart: (f64, i32))
                                  (log_Qdiag: [p]f64) (ltri_Q: [tri_p]f64) : f64 =
  let wishart_gamma = wishart.1
  let wishart_m = wishart.2
  let n = p + (wishart_m + 1)
  in (0.5 * ((wishart_gamma * wishart_gamma) * (sqnorm (exp_VecR log_Qdiag) + sqnorm ltri_Q)) - (to_float wishart_m * sum log_Qdiag)) - (to_float (n * p) * (log wishart_gamma - (0.5 * log 2.0)) - (log_gamma_distrib (0.5 * to_float n)
                                                                                                                                                                                                                       p))

let gmm_knossos_gmm_objective [N] [D] [K] [triD] (x: [N][D]f64)
                                                 (alphas: [K]f64) (means: [K][D]f64) (qs: [K][D]f64)
                                                 (ls: [K][triD]f64) (wishart: (f64, i32)) : f64 =
  (to_float (N * D) * neg 0.9189385332046727 + (reduce (+)
                                                       0.0
                                                       (tabulate N
                                                                 (\i ->
                                                                     logsumexp (build K
                                                                                      (\k ->
                                                                                          let t884 = qs[k]
                                                                                          in (alphas[k] + sum t884) - (0.5 * sqnorm (mul_Mat_Vec (gmm_knossos_makeQ t884
                                                                                                                                                                    ls[k])
                                                                                                                                                 (sub_VecR_VecR x[i]
                                                                                                                                                                means[k]))))))) - (to_float N * logsumexp alphas))) + reduce (+)
                                                                                                                                                                                                                             0.0
                                                                                                                                                                                                                             (tabulate K
                                                                                                                                                                                                                                       (\k ->
                                                                                                                                                                                                                                           log_wishart_prior wishart
                                                                                                                                                                                                                                                             qs[k]
                                                                                                                                                                                                                                                             ls[k]))

let get_2_6_6 [N] [D] [K] [triD] (t: ([N][D]f64,
                                      [K]f64,
                                      [K][D]f64,
                                      [K][D]f64,
                                      [K][triD]f64,
                                      (f64, ()))) : ([K]f64,
                                                     [K][D]f64,
                                                     [K][D]f64,
                                                     [K][triD]f64,
                                                     (f64, ())) =
  (t.2, t.3, t.4, t.5, t.6)

let mkvec (n: i32) (scale: f64) : [n]f64 =
  build n (\j -> u_rand scale)

let zerov [n] (x: [n]f64) : [n]f64 = mul_R_VecR 0.0 x

let zerovv [m] [n] (x: [m][n]f64) : [m][n]f64 = mul_R_VecVecR 0.0 x

let mkdeltav (n: i32) (i: i32) (val_: f64) : [n]f64 =
  deltaVec 0.0 n i val_

let mkdeltavv [m] [n] (x: [m][n]f64) (i: i32) (j: i32)
                      (val_: f64) : [m][n]f64 =
  build m
        (\ii -> build n (\jj -> delta 0.0 i ii (delta 0.0 j jj val_)))

let vottotov4 [N] [D] [triD] (x: [N](f64,
                                     [D]f64,
                                     [D]f64,
                                     [triD]f64)) : ([N]f64, [N][D]f64, [N][D]f64, [N][triD]f64) =
  (build N (\i -> (x[i]).1),
   build N (\i -> (x[i]).2),
   build N (\i -> (x[i]).3),
   build N (\i -> (x[i]).4))

let fwd_gmm_knossos_tri (n: i32) (d_n: ()) : () = ()

let fwd_exp_VecR [n] (v: [n]f64) (d_v: [n]f64) : [n]f64 =
  build n (\i -> exp v[i] * d_v[i])

let fwd_mul_R_VecR [n] (r: f64) (a: [n]f64) (d_r: f64)
                       (d_a: [n]f64) : [n]f64 =
  build n (\i -> a[i] * d_r + r * ((constVec n 0.0)[i] + d_a[i]))

let fwd_mul_R_VecVecR [m] [n] (r: f64) (a: [m][n]f64) (d_r: f64)
                              (d_a: [m][n]f64) : [m][n]f64 =
  build m
        (\i ->
            fwd_mul_R_VecR r
                           a[i]
                           d_r
                           (map2 (+) (constVec m (constVec n 0.0))[i] d_a[i]))

let fwd_mul_VecR_VecR [n] (a: [n]f64) (b: [n]f64) (d_a: [n]f64)
                          (d_b: [n]f64) : [n]f64 =
  build n
        (\i ->
            let t939 = (constVec n 0.0)[i]
            in b[i] * (d_a[i] + t939) + a[i] * (t939 + d_b[i]))

let fwd_sub_VecR_VecR [n] (a: [n]f64) (b: [n]f64) (d_a: [n]f64)
                          (d_b: [n]f64) : [n]f64 =
  build n
        (\i ->
            let t950 = (constVec n 0.0)[i]
            in (d_a[i] + t950) + -1.0 * (t950 + d_b[i]))

let fwd_dotvv [m] [n] (a: [m][n]f64) (b: [m][n]f64)
                      (d_a: [m][n]f64) (d_b: [m][n]f64) : f64 =
  reduce (+)
         0.0
         (tabulate m
                   (\sum_i ->
                       let t962 = (constVec m (constVec n 0.0))[sum_i]
                       in fwd_dotv a[sum_i]
                                   b[sum_i]
                                   (map2 (+) d_a[sum_i] t962)
                                   (map2 (+) t962 d_b[sum_i])))

let fwd_sqnorm [n] (v: [n]f64) (d_v: [n]f64) : f64 =
  fwd_dotv v v d_v d_v

let fwd_gmm_knossos_makeQ [D] [triD] (q: [D]f64) (l: [triD]f64)
                                     (d_q: [D]f64) (d_l: [triD]f64) : [D][D]f64 =
  build D
        (\i ->
            build D
                  (\j ->
                      if i < j
                      then 0.0
                      else if i == j
                           then exp q[i] * (d_q[i] + (constVec D 0.0)[i])
                           else let t977 = gmm_knossos_tri i + j
                                in (constVec triD 0.0)[t977] + d_l[t977]))

let fwd_logsumexp [n] (v: [n]f64) (d_v: [n]f64) : f64 =
  (1.0 / (sum (exp_VecR v))) * reduce (+)
                                      0.0
                                      (tabulate n (\sum_i -> (fwd_exp_VecR v d_v)[sum_i]))

let fwd_log_gamma_distrib (a: f64) (p: i32) (d_a: f64)
                          (d_p: ()) : f64 =
  reduce (+)
         0.0
         (tabulate p (\sum_i -> digamma (a - (0.5 * to_float sum_i)) * d_a))

let fwd_log_wishart_prior [p] [tri_p] (wishart: (f64, i32))
                                      (log_Qdiag: [p]f64) (ltri_Q: [tri_p]f64)
                                      (d_wishart: (f64, ())) (d_log_Qdiag: [p]f64)
                                      (d_ltri_Q: [tri_p]f64) : f64 =
  let wishart_gamma = wishart.1
  let wishart_m = wishart.2
  let Qdiag = exp_VecR log_Qdiag
  let n = p + (wishart_m + 1)
  let t998 = d_wishart.1
  let t1000 = wishart_gamma * wishart_gamma
  let t1003 = fwd_sqnorm Qdiag
                         (fwd_exp_VecR log_Qdiag (constVec p 0.0))
  let t1005 = fwd_sqnorm ltri_Q (constVec tri_p 0.0)
  let t1028 = to_float wishart_m
  let t1032 = -1.0 * (t1028 * reduce (+)
                                     0.0
                                     (tabulate p (\sum_i -> (constVec p 0.0)[sum_i])))
  in ((0.5 * (((sqnorm Qdiag + sqnorm ltri_Q) * (wishart_gamma + wishart_gamma)) * t998 + t1000 * (t1003 + t1005)) + (0.5 * (t1000 * (fwd_sqnorm Qdiag
                                                                                                                                                 (fwd_exp_VecR log_Qdiag
                                                                                                                                                               d_log_Qdiag) + t1005)) + 0.5 * (t1000 * (t1003 + fwd_sqnorm ltri_Q
                                                                                                                                                                                                                           d_ltri_Q)))) + (t1032 + (-1.0 * (t1028 * reduce (+)
                                                                                                                                                                                                                                                                           0.0
                                                                                                                                                                                                                                                                           (tabulate p
                                                                                                                                                                                                                                                                                     (\sum_i ->
                                                                                                                                                                                                                                                                                         d_log_Qdiag[sum_i]))) + t1032))) + -1.0 * (to_float (n * p) * ((1.0 / wishart_gamma) * t998) + -1.0 * fwd_log_gamma_distrib (0.5 * to_float n)
                                                                                                                                                                                                                                                                                                                                                                                                                     p
                                                                                                                                                                                                                                                                                                                                                                                                                     0.0
                                                                                                                                                                                                                                                                                                                                                                                                                     ())

let fwd_gmm_knossos_gmm_objective [N] [D] [K] [triD] (x: [N][D]f64)
                                                     (alphas: [K]f64) (means: [K][D]f64)
                                                     (qs: [K][D]f64) (ls: [K][triD]f64)
                                                     (wishart: (f64, i32)) (d_x: [N][D]f64)
                                                     (d_alphas: [K]f64) (d_means: [K][D]f64)
                                                     (d_qs: [K][D]f64) (d_ls: [K][triD]f64)
                                                     (d_wishart: (f64, ())) : f64 =
  let t1217 = to_float N
  let t1220 = t1217 * fwd_logsumexp alphas (constVec K 0.0)
  in (reduce (+)
             0.0
             (tabulate N
                       (\sum_i ->
                           fwd_logsumexp (build K
                                                (\k ->
                                                    let t1060 = qs[k]
                                                    in (alphas[k] + sum t1060) - (0.5 * sqnorm (mul_Mat_Vec (gmm_knossos_makeQ t1060
                                                                                                                               ls[k])
                                                                                                            (sub_VecR_VecR x[sum_i]
                                                                                                                           means[k])))))
                                         (build K
                                                (\k ->
                                                    let t1073 = qs[k]
                                                    let t1074 = ls[k]
                                                    let Q = gmm_knossos_makeQ t1073 t1074
                                                    let t1076 = (constVec K 0.0)[k]
                                                    let t1114 = x[sum_i]
                                                    let t1115 = means[k]
                                                    let t1116 = sub_VecR_VecR t1114 t1115
                                                    let t1125 = (constVec K (constVec D 0.0))[k]
                                                    let t1139 = map2 (+) t1125 t1125
                                                    let t1146 = (constVec K (constVec triD 0.0))[k]
                                                    let t1171 = (constVec N (constVec D 0.0))[sum_i]
                                                    in ((t1076 + (d_alphas[k] + (t1076 + (t1076 + (t1076 + t1076))))) + reduce (+)
                                                                                                                               0.0
                                                                                                                               (tabulate D
                                                                                                                                         (\sum_i_1 ->
                                                                                                                                             let t1093 = (constVec K
                                                                                                                                                                   (constVec D
                                                                                                                                                                             0.0))[k]
                                                                                                                                             in (map2 (+) t1093
                                                                                                                                                          (map2 (+) t1093
                                                                                                                                                                    (map2 (+) t1093
                                                                                                                                                                              (map2 (+) d_qs[k]
                                                                                                                                                                                        (map2 (+) t1093
                                                                                                                                                                                                  t1093)))))[sum_i_1]))) + -1.0 * (0.5 * fwd_sqnorm (mul_Mat_Vec Q
                                                                                                                                                                                                                                                                 t1116)
                                                                                                                                                                                                                                                    (fwd_mul_Mat_Vec Q
                                                                                                                                                                                                                                                                     t1116
                                                                                                                                                                                                                                                                     (fwd_gmm_knossos_makeQ t1073
                                                                                                                                                                                                                                                                                            t1074
                                                                                                                                                                                                                                                                                            (map2 (+) t1125
                                                                                                                                                                                                                                                                                                      (map2 (+) t1125
                                                                                                                                                                                                                                                                                                                (map2 (+) t1125
                                                                                                                                                                                                                                                                                                                          (map2 (+) d_qs[k]
                                                                                                                                                                                                                                                                                                                                    t1139))))
                                                                                                                                                                                                                                                                                            (map2 (+) t1146
                                                                                                                                                                                                                                                                                                      (map2 (+) t1146
                                                                                                                                                                                                                                                                                                                (map2 (+) t1146
                                                                                                                                                                                                                                                                                                                          (map2 (+) t1146
                                                                                                                                                                                                                                                                                                                                    (map2 (+) d_ls[k]
                                                                                                                                                                                                                                                                                                                                              t1146))))))
                                                                                                                                                                                                                                                                     (fwd_sub_VecR_VecR t1114
                                                                                                                                                                                                                                                                                        t1115
                                                                                                                                                                                                                                                                                        (map2 (+) d_x[sum_i]
                                                                                                                                                                                                                                                                                                  (map2 (+) t1171
                                                                                                                                                                                                                                                                                                            (map2 (+) t1171
                                                                                                                                                                                                                                                                                                                      (map2 (+) t1171
                                                                                                                                                                                                                                                                                                                                (map2 (+) t1171
                                                                                                                                                                                                                                                                                                                                          t1171)))))
                                                                                                                                                                                                                                                                                        (map2 (+) t1125
                                                                                                                                                                                                                                                                                                  (map2 (+) t1125
                                                                                                                                                                                                                                                                                                            (map2 (+) d_means[k]
                                                                                                                                                                                                                                                                                                                      (map2 (+) t1125
                                                                                                                                                                                                                                                                                                                                t1139))))))))))) + -1.0 * (t1220 + (t1217 * fwd_logsumexp alphas
                                                                                                                                                                                                                                                                                                                                                                                          d_alphas + (t1220 + (t1220 + (t1220 + t1220)))))) + reduce (+)
                                                                                                                                                                                                                                                                                                                                                                                                                                                     0.0
                                                                                                                                                                                                                                                                                                                                                                                                                                                     (tabulate K
                                                                                                                                                                                                                                                                                                                                                                                                                                                               (\sum_i ->
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   let t1251 = (constVec K
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         (constVec D
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   0.0))[sum_i]
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   let t1272 = (constVec K
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         (constVec triD
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   0.0))[sum_i]
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   in fwd_log_wishart_prior wishart
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            qs[sum_i]
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ls[sum_i]
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            d_wishart
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            (map2 (+) t1251
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      (map2 (+) t1251
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                (map2 (+) t1251
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          (map2 (+) d_qs[sum_i]
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    (map2 (+) t1251
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              t1251)))))
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            (map2 (+) t1272
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      (map2 (+) t1272
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                (map2 (+) t1272
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          (map2 (+) t1272
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    (map2 (+) d_ls[sum_i]
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              t1272)))))))

let fwd_get_2_6_6 [N] [D] [K] [triD] (t: ([N][D]f64,
                                          [K]f64,
                                          [K][D]f64,
                                          [K][D]f64,
                                          [K][triD]f64,
                                          (f64, ())))
                                     (d_t: ([N][D]f64,
                                            [K]f64,
                                            [K][D]f64,
                                            [K][D]f64,
                                            [K][triD]f64,
                                            (f64, ()))) : ([K]f64,
                                                           [K][D]f64,
                                                           [K][D]f64,
                                                           [K][triD]f64,
                                                           (f64, ())) =
  (d_t.2, d_t.3, d_t.4, d_t.5, d_t.6)

let fwd_mkvec (n: i32) (scale: f64) (d_n: ())
              (d_scale: f64) : [n]f64 =
  build n (\j -> 0.0)

let fwd_zerov [n] (x: [n]f64) (d_x: [n]f64) : [n]f64 =
  fwd_mul_R_VecR 0.0 x 0.0 d_x

let fwd_zerovv [m] [n] (x: [m][n]f64)
                       (d_x: [m][n]f64) : [m][n]f64 =
  fwd_mul_R_VecVecR 0.0 x 0.0 d_x

let fwd_mkdeltav (n: i32) (i: i32) (val_: f64) (d_n: ()) (d_i: ())
                 (d_val: f64) : [n]f64 =
  deltaVec 0.0 n i d_val

let fwd_mkdeltavv [m] [n] (x: [m][n]f64) (i: i32) (j: i32)
                          (val_: f64) (d_x: [m][n]f64) (d_i: ()) (d_j: ())
                          (d_val: f64) : [m][n]f64 =
  build m
        (\ii -> build n (\jj -> delta 0.0 i ii (delta 0.0 j jj d_val)))

let fwd_vottotov4 [N] [D] [triD] (x: [N](f64,
                                         [D]f64,
                                         [D]f64,
                                         [triD]f64))
                                 (d_x: [N](f64, [D]f64, [D]f64, [triD]f64)) : ([N]f64,
                                                                               [N][D]f64,
                                                                               [N][D]f64,
                                                                               [N][triD]f64) =
  (build N (\i -> (d_x[i]).1),
   build N (\i -> (d_x[i]).2),
   build N (\i -> (d_x[i]).3),
   build N (\i -> (d_x[i]).4))

let rev_gmm_knossos_tri (n: i32) (d_r: ()) : () = ()

let rev_exp_VecR [n] (v: [n]f64) (d_r: [n]f64) : [n]f64 =
  build n (\i -> exp v[i] * d_r[i])

let rev_mul_R_VecR [n] (r: f64) (a: [n]f64) (d_r: [n]f64) : (f64,
                                                             [n]f64) =
  (reduce (+) 0.0 (tabulate n (\i -> a[i] * d_r[i])),
   build n (\i -> r * d_r[i]))

let rev_mul_R_VecVecR [m] [n] (r: f64) (a: [m][n]f64)
                              (d_r: [m][n]f64) : (f64, [m][n]f64) =
  (reduce (+)
          0.0
          (tabulate m (\i -> (rev_mul_R_VecR r a[i] d_r[i]).1)),
   build m (\i -> (rev_mul_R_VecR r a[i] d_r[i]).2))

let rev_mul_VecR_VecR [n] (a: [n]f64) (b: [n]f64)
                          (d_r: [n]f64) : ([n]f64, [n]f64) =
  (build n (\i -> b[i] * d_r[i]), build n (\i -> a[i] * d_r[i]))

let rev_sub_VecR_VecR [n] (a: [n]f64) (b: [n]f64)
                          (d_r: [n]f64) : ([n]f64, [n]f64) =
  (build n (\i -> d_r[i]), build n (\i -> -1.0 * d_r[i]))

let rev_dotvv [m] [n] (a: [m][n]f64) (b: [m][n]f64)
                      (d_r: f64) : ([m][n]f64, [m][n]f64) =
  (build m (\i -> (rev_dotv a[i] b[i] d_r).1),
   build m (\i -> (rev_dotv a[i] b[i] d_r).2))

let rev_sqnorm [n] (v: [n]f64) (d_r: f64) : [n]f64 =
  let t1339 = rev_dotv v v d_r
  in map2 (+) t1339.1 t1339.2

let rev_gmm_knossos_makeQ [D] [triD] (q: [D]f64) (l: [triD]f64)
                                     (d_r: [D][D]f64) : ([D]f64, [triD]f64) =
  let x = tabulate D
                   (\i ->
                       let x = tabulate D
                                        (\j ->
                                            if i < j
                                            then (constVec D 0.0, constVec triD 0.0)
                                            else if i == j
                                                 then (deltaVec 0.0 D i (exp q[i] * d_r[i , j]),
                                                       constVec triD 0.0)
                                                 else (constVec D 0.0,
                                                       deltaVec 0.0
                                                                triD
                                                                (gmm_knossos_tri i + j)
                                                                d_r[i , j]))
                       in (map (\row -> reduce (+) 0.0 row) (transpose (map (.1) x)),
                           map (\row -> reduce (+) 0.0 row) (transpose (map (.2) x))))
  in (map (\row -> reduce (+) 0.0 row) (transpose (map (.1) x)),
      map (\row -> reduce (+) 0.0 row) (transpose (map (.2) x)))

let rev_logsumexp [n] (v: [n]f64) (d_r: f64) : [n]f64 =
  rev_exp_VecR v
               (build n (\sum_i -> (1.0 / (sum (exp_VecR v))) * d_r))

let rev_log_gamma_distrib (a: f64) (p: i32) (d_r: f64) : (f64,
                                                          ()) =
  (reduce (+)
          0.0
          (tabulate p (\j -> digamma (a - (0.5 * to_float j)) * d_r)),
   ())

let rev_log_wishart_prior [p] [tri_p] (wishart: (f64, i32))
                                      (log_Qdiag: [p]f64) (ltri_Q: [tri_p]f64) (d_r: f64) : ((f64,
                                                                                              ()),
                                                                                             [p]f64,
                                                                                             [tri_p]f64) =
  let wishart_gamma = wishart.1
  let wishart_m = wishart.2
  let Qdiag = exp_VecR log_Qdiag
  let t1374 = 0.5 * d_r
  let t1381 = -1.0 * d_r
  let t1389 = (wishart_gamma * wishart_gamma) * t1374
  in ((((sqnorm Qdiag + sqnorm ltri_Q) * (wishart_gamma + wishart_gamma)) * t1374 + (1.0 / wishart_gamma) * (to_float ((p + (wishart_m + 1)) * p) * t1381),
       ()),
      map2 (+) (rev_exp_VecR log_Qdiag (rev_sqnorm Qdiag t1389))
               (build p (\sum_i -> to_float wishart_m * t1381)),
      rev_sqnorm ltri_Q t1389)

let rev_gmm_knossos_gmm_objective [N] [D] [K] [triD] (x: [N][D]f64)
                                                     (alphas: [K]f64) (means: [K][D]f64)
                                                     (qs: [K][D]f64) (ls: [K][triD]f64)
                                                     (wishart: (f64, i32)) (d_r: f64) : ([N][D]f64,
                                                                                         [K]f64,
                                                                                         [K][D]f64,
                                                                                         [K][D]f64,
                                                                                         [K][triD]f64,
                                                                                         (f64,
                                                                                          ())) =
  (\(x: ([N][D]f64,
         [K]f64,
         [K][D]f64,
         [K][D]f64,
         [K][triD]f64,
         (f64, ())))
    (y: ([N][D]f64,
         [K]f64,
         [K][D]f64,
         [K][D]f64,
         [K][triD]f64,
         (f64, ()))) ->
      (map2 (map2 (+)) x.1 y.1,
       map2 (+) x.2 y.2,
       map2 (map2 (+)) x.3 y.3,
       map2 (map2 (+)) x.4 y.4,
       map2 (map2 (+)) x.5 y.5,
       (\(x: (f64, ())) (y: (f64, ())) ->
           ((+) x.1 y.1, (\(x: ()) (y: ()) -> ()) x.2 y.2)) x.6
                                                            y.6)) ((\(x: ([N][D]f64,
                                                                          [K]f64,
                                                                          [K][D]f64,
                                                                          [K][D]f64,
                                                                          [K][triD]f64,
                                                                          (f64, ())))
                                                                     (y: ([N][D]f64,
                                                                          [K]f64,
                                                                          [K][D]f64,
                                                                          [K][D]f64,
                                                                          [K][triD]f64,
                                                                          (f64, ()))) ->
                                                                       (map2 (map2 (+)) x.1 y.1,
                                                                        map2 (+) x.2 y.2,
                                                                        map2 (map2 (+)) x.3 y.3,
                                                                        map2 (map2 (+)) x.4 y.4,
                                                                        map2 (map2 (+)) x.5 y.5,
                                                                        (\(x: (f64, ()))
                                                                          (y: (f64, ())) ->
                                                                            ((+) x.1 y.1,
                                                                             (\(x: ()) (y: ()) ->
                                                                                 ()) x.2 y.2)) x.6
                                                                                               y.6)) (let x = tabulate N
                                                                                                                       (\i ->
                                                                                                                          let t1403 = x[i]
                                                                                                                           let x = tabulate K
                                                                                                                                            (\k ->
                                                                                                                                                let t1401 = qs[k]
                                                                                                                                                let t1402 = ls[k]
                                                                                                                                                let Q = gmm_knossos_makeQ t1401
                                                                                                                                                                          t1402
                                                                                                                                                let t1404 = means[k]
                                                                                                                                                let t1405 = sub_VecR_VecR t1403
                                                                                                                                                                          t1404
                                                                                                                                                let t1426 = (rev_logsumexp (build K
                                                                                                                                                                                  (\k_1 ->
                                                                                                                                                                                      let t1412 = qs[k_1]
                                                                                                                                                                                      in (alphas[k_1] + sum t1412) - (0.5 * sqnorm (mul_Mat_Vec (gmm_knossos_makeQ t1412
                                                                                                                                                                                                                                                                   ls[k_1])
                                                                                                                                                                                                                                                (sub_VecR_VecR t1403
                                                                                                                                                                                                                                                               means[k_1])))))
                                                                                                                                                                           d_r)[k]
                                                                                                                                                let t1430 = rev_mul_Mat_Vec Q
                                                                                                                                                                            t1405
                                                                                                                                                                            (rev_sqnorm (mul_Mat_Vec Q
                                                                                                                                                                                                     t1405)
                                                                                                                                                                                        (0.5 * (-1.0 * t1426)))
                                                                                                                                                let t1432 = rev_sub_VecR_VecR t1403
                                                                                                                                                                              t1404
                                                                                                                                                                              t1430.2
                                                                                                                                                let t1523 = rev_gmm_knossos_makeQ t1401
                                                                                                                                                                                  t1402
                                                                                                                                                                                  t1430.1
                                                                                                                                                in (t1432.1,
                                                                                                                                                    t1426,
                                                                                                                                                    t1432.2,
                                                                                                                                                    (map2 (+) (build D (\sum_i -> t1426)) t1523.1),
                                                                                                                                                    t1523.2,
                                                                                                                                                    (0.0,
                                                                                                                                                     ())))
                                                                                                                           in ((map (.1) x),
                                                                                                                               (map (.2) x),
                                                                                                                               map (.3) x,
                                                                                                                               (map (.4) x),
                                                                                                                               (map (.5) x),
                                                                                                                               let x = map (.6)
                                                                                                                                           x
                                                                                                                               in (reduce (+)
                                                                                                                                          0.0
                                                                                                                                          (map (.1)
                                                                                                                                               x),
                                                                                                                                   ())))
                                                                                                      in (map (\row ->
                                                                                                                  map (\row ->
                                                                                                                          reduce (+)
                                                                                                                                 0.0
                                                                                                                                 row)
                                                                                                                      (transpose row))
                                                                                                              (transpose (map (.1)
                                                                                                                              x)),
                                                                                                          map (\row ->
                                                                                                                  reduce (+)
                                                                                                                         0.0
                                                                                                                         row)
                                                                                                              (transpose (map (.2)
                                                                                                                              x)),
                                                                                                          map (\row ->
                                                                                                                  map (\row ->
                                                                                                                          reduce (+)
                                                                                                                                 0.0
                                                                                                                                 row)
                                                                                                                      (transpose row))
                                                                                                              (transpose (map (.3)
                                                                                                                              x)),
                                                                                                          map (\row ->
                                                                                                                  map (\row ->
                                                                                                                          reduce (+)
                                                                                                                                 0.0
                                                                                                                                 row)
                                                                                                                      (transpose row))
                                                                                                              (transpose (map (.4)
                                                                                                                              x)),
                                                                                                          map (\row ->
                                                                                                                  map (\row ->
                                                                                                                          reduce (+)
                                                                                                                                 0.0
                                                                                                                                 row)
                                                                                                                      (transpose row))
                                                                                                              (transpose (map (.5)
                                                                                                                              x)),
                                                                                                          let x = map (.6)
                                                                                                                      x
                                                                                                          in (reduce (+)
                                                                                                                     0.0
                                                                                                                     (map (.1)
                                                                                                                          x),
                                                                                                              ())))
                                                                                                     (constVec N
                                                                                                               (constVec D
                                                                                                                         0.0),
                                                                                                      rev_logsumexp alphas
                                                                                                                    (to_float N * (-1.0 * d_r)),
                                                                                                      constVec K
                                                                                                               (constVec D
                                                                                                                         0.0),
                                                                                                      constVec K
                                                                                                               (constVec D
                                                                                                                         0.0),
                                                                                                      constVec K
                                                                                                               (constVec triD
                                                                                                                         0.0),
                                                                                                      (0.0,
                                                                                                       ())))
                                                                  (constVec N (constVec D 0.0),
                                                                   constVec K 0.0,
                                                                   constVec K (constVec D 0.0),
                                                                   build K
                                                                         (\k ->
                                                                             (rev_log_wishart_prior wishart
                                                                                                    qs[k]
                                                                                                    ls[k]
                                                                                                    d_r).2),
                                                                   build K
                                                                         (\k ->
                                                                             (rev_log_wishart_prior wishart
                                                                                                    qs[k]
                                                                                                    ls[k]
                                                                                                    d_r).3),
                                                                   let x = tabulate K
                                                                                    (\k ->
                                                                                        (rev_log_wishart_prior wishart
                                                                                                               qs[k]
                                                                                                               ls[k]
                                                                                                               d_r).1)
                                                                   in (reduce (+) 0.0 (map (.1) x),
                                                                       ()))

let rev_get_2_6_6 [N] [D] [K] [triD] (t: ([N][D]f64,
                                          [K]f64,
                                          [K][D]f64,
                                          [K][D]f64,
                                          [K][triD]f64,
                                          (f64, ())))
                                     (d_r: ([K]f64,
                                            [K][D]f64,
                                            [K][D]f64,
                                            [K][triD]f64,
                                            (f64, ()))) : ([N][D]f64,
                                                           [K]f64,
                                                           [K][D]f64,
                                                           [K][D]f64,
                                                           [K][triD]f64,
                                                           (f64, ())) =
  (constVec N (constVec D 0.0), d_r.1, d_r.2, d_r.3, d_r.4, d_r.5)

let rev_mkvec (n: i32) (scale: f64) (d_r: [n]f64) : ((), f64) =
  ((), 0.0)

let rev_zerov [n] (x: [n]f64) (d_r: [n]f64) : [n]f64 =
  (rev_mul_R_VecR 0.0 x d_r).2

let rev_zerovv [m] [n] (x: [m][n]f64)
                       (d_r: [m][n]f64) : [m][n]f64 =
  (rev_mul_R_VecVecR 0.0 x d_r).2

let rev_mkdeltav (n: i32) (i: i32) (val_: f64) (d_r: [n]f64) : ((),
                                                                (),
                                                                f64) =
  ((), (), d_r[i])

let rev_mkdeltavv [m] [n] (x: [m][n]f64) (i: i32) (j: i32)
                          (val_: f64) (d_r: [m][n]f64) : ([m][n]f64, (), (), f64) =
  let x = tabulate m
                   (\ii ->
                       let x = tabulate n
                                        (\jj ->
                                            delta (replicate m (replicate n 0.0), (), (), 0.0)
                                                  i
                                                  ii
                                                  (delta (replicate m (replicate n 0.0),
                                                          (),
                                                          (),
                                                          0.0)
                                                         j
                                                         jj
                                                         (constVec m (constVec n 0.0),
                                                          (),
                                                          (),
                                                          d_r[ii , jj])))
                       in (map (\row -> map (\row -> reduce (+) 0.0 row) (transpose row))
                               (transpose (map (.1) x)),
                           (),
                           (),
                           reduce (+) 0.0 (map (.4) x)))
  in (map (\row -> map (\row -> reduce (+) 0.0 row) (transpose row))
          (transpose (map (.1) x)),
      (),
      (),
      reduce (+) 0.0 (map (.4) x))

let rev_vottotov4 [N] [D] [triD] (x: [N](f64,
                                         [D]f64,
                                         [D]f64,
                                         [triD]f64))
                                 (d_r: ([N]f64, [N][D]f64, [N][D]f64, [N][triD]f64)) : [N](f64,
                                                                                           [D]f64,
                                                                                           [D]f64,
                                                                                           [triD]f64) =
  map2 (\(x: (f64, [D]f64, [D]f64, [triD]f64))
         (y: (f64, [D]f64, [D]f64, [triD]f64)) ->
           ((+) x.1 y.1,
            map2 (+) x.2 y.2,
            map2 (+) x.3 y.3,
            map2 (+) x.4 y.4)) (map (\row ->
                                        (reduce (+) 0.0 (map (.1) row),
                                         map (\row -> reduce (+) 0.0 row)
                                             (transpose (map (.2) row)),
                                         map (\row -> reduce (+) 0.0 row)
                                             (transpose (map (.3) row)),
                                         map (\row -> reduce (+) 0.0 row)
                                             (transpose (map (.4) row))))
                                    (transpose (tabulate N
                                                         (\i ->
                                                             deltaVec (0.0,
                                                                       replicate D 0.0,
                                                                       replicate D 0.0,
                                                                       replicate triD 0.0)
                                                                      N
                                                                      i
                                                                      ((d_r.1)[i],
                                                                       constVec D 0.0,
                                                                       constVec D 0.0,
                                                                       constVec triD 0.0)))))
                               (map2 (\(x: (f64, [D]f64, [D]f64, [triD]f64))
                                       (y: (f64, [D]f64, [D]f64, [triD]f64)) ->
                                         ((+) x.1 y.1,
                                          map2 (+) x.2 y.2,
                                          map2 (+) x.3 y.3,
                                          map2 (+) x.4 y.4)) (map (\row ->
                                                                      (reduce (+)
                                                                              0.0
                                                                              (map (.1) row),
                                                                       map (\row ->
                                                                               reduce (+) 0.0 row)
                                                                           (transpose (map (.2)
                                                                                           row)),
                                                                       map (\row ->
                                                                               reduce (+) 0.0 row)
                                                                           (transpose (map (.3)
                                                                                           row)),
                                                                       map (\row ->
                                                                               reduce (+) 0.0 row)
                                                                           (transpose (map (.4)
                                                                                           row))))
                                                                  (transpose (tabulate N
                                                                                       (\i ->
                                                                                           deltaVec (0.0,
                                                                                                     replicate D
                                                                                                               0.0,
                                                                                                     replicate D
                                                                                                               0.0,
                                                                                                     replicate triD
                                                                                                               0.0)
                                                                                                    N
                                                                                                    i
                                                                                                    (0.0,
                                                                                                     (d_r.2)[i],
                                                                                                     constVec D
                                                                                                              0.0,
                                                                                                     constVec triD
                                                                                                              0.0)))))
                                                             (map2 (\(x: (f64,
                                                                          [D]f64,
                                                                          [D]f64,
                                                                          [triD]f64))
                                                                     (y: (f64,
                                                                          [D]f64,
                                                                          [D]f64,
                                                                          [triD]f64)) ->
                                                                       ((+) x.1 y.1,
                                                                        map2 (+) x.2 y.2,
                                                                        map2 (+) x.3 y.3,
                                                                        map2 (+) x.4
                                                                                 y.4)) (map (\row ->
                                                                                                (reduce (+)
                                                                                                        0.0
                                                                                                        (map (.1)
                                                                                                             row),
                                                                                                 map (\row ->
                                                                                                         reduce (+)
                                                                                                                0.0
                                                                                                                row)
                                                                                                     (transpose (map (.2)
                                                                                                                     row)),
                                                                                                 map (\row ->
                                                                                                         reduce (+)
                                                                                                                0.0
                                                                                                                row)
                                                                                                     (transpose (map (.3)
                                                                                                                     row)),
                                                                                                 map (\row ->
                                                                                                         reduce (+)
                                                                                                                0.0
                                                                                                                row)
                                                                                                     (transpose (map (.4)
                                                                                                                     row))))
                                                                                            (transpose (tabulate N
                                                                                                                 (\i ->
                                                                                                                     deltaVec (0.0,
                                                                                                                               replicate D
                                                                                                                                         0.0,
                                                                                                                               replicate D
                                                                                                                                         0.0,
                                                                                                                               replicate triD
                                                                                                                                         0.0)
                                                                                                                              N
                                                                                                                              i
                                                                                                                              (0.0,
                                                                                                                               constVec D
                                                                                                                                        0.0,
                                                                                                                               (d_r.3)[i],
                                                                                                                               constVec triD
                                                                                                                                        0.0)))))
                                                                                       (map (\row ->
                                                                                                (reduce (+)
                                                                                                        0.0
                                                                                                        (map (.1)
                                                                                                             row),
                                                                                                 map (\row ->
                                                                                                         reduce (+)
                                                                                                                0.0
                                                                                                                row)
                                                                                                     (transpose (map (.2)
                                                                                                                     row)),
                                                                                                 map (\row ->
                                                                                                         reduce (+)
                                                                                                                0.0
                                                                                                                row)
                                                                                                     (transpose (map (.3)
                                                                                                                     row)),
                                                                                                 map (\row ->
                                                                                                         reduce (+)
                                                                                                                0.0
                                                                                                                row)
                                                                                                     (transpose (map (.4)
                                                                                                                     row))))
                                                                                            (transpose (tabulate N
                                                                                                                 (\i ->
                                                                                                                     deltaVec (0.0,
                                                                                                                               replicate D
                                                                                                                                         0.0,
                                                                                                                               replicate D
                                                                                                                                         0.0,
                                                                                                                               replicate triD
                                                                                                                                         0.0)
                                                                                                                              N
                                                                                                                              i
                                                                                                                              (0.0,
                                                                                                                               constVec D
                                                                                                                                        0.0,
                                                                                                                               constVec D
                                                                                                                                        0.0,
                                                                                                                               (d_r.4)[i])))))))
