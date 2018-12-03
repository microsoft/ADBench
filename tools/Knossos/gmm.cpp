#include "knossos.h"
#include <stdio.h>
namespace ks {

int gmm_knossos_tri(int s$n) {
  /**Call**/ /**Call**/
  /**Call**/
  int c$0 = sub(s$n, 1);
  /**eCall**/
  int c$1 = mul(s$n, c$0);
  /**eCall**/

  int c$2 = div(c$1, 2);
  /**eCall**/
  return c$2;
}

vec<double> exp$VecR(vec<double> s$v) {
  /**Call**/ /**Ex**/
  auto c$0 = size(s$v);
  /**eEx*/

  /**Lam**/ auto c$1 = [&](int s$i) { /**Ex**/
                                      /**Call**/
                                      double c$3 = index(s$i, s$v);
                                      /**eCall**/
                                      auto c$2 = exp(c$3);
                                      /**eEx*/
                                      return c$2;
  };
  vec<double> c$4 = build<double>(c$0, c$1);
  /**eCall**/
  return c$4;
}

vec<double> mul$VecR$VecR(vec<double> s$a, vec<double> s$b) {
  /**Call**/ /**Ex**/
  auto c$0 = size(s$a);
  /**eEx*/

  /**Ex**/
  auto c$1 = size(s$b);
  /**eEx*/
  bool c$2 = eq(c$0, c$1);
  /**eCall**/
  ASSERT(c$2);
  /**Call**/ /**Ex**/
  auto c$3 = size(s$b);
  /**eEx*/

  /**Lam**/ auto c$4 = [&](int s$i) { /**Call**/ /**Call**/
                                      double c$5 = index(s$i, s$a);
                                      /**eCall**/

                                      /**Call**/
                                      double c$6 = index(s$i, s$b);
                                      /**eCall**/
                                      double c$7 = mul(c$5, c$6);
                                      /**eCall**/
                                      return c$7;
  };
  vec<double> c$8 = build<double>(c$3, c$4);
  /**eCall**/
  return c$8;
}

vec<double> sub$VecR$VecR(vec<double> s$a, vec<double> s$b) {
  /**Call**/ /**Ex**/
  auto c$0 = size(s$a);
  /**eEx*/

  /**Ex**/
  auto c$1 = size(s$b);
  /**eEx*/
  bool c$2 = eq(c$0, c$1);
  /**eCall**/
  ASSERT(c$2);
  /**Call**/ /**Ex**/
  auto c$3 = size(s$b);
  /**eEx*/

  /**Lam**/ auto c$4 = [&](int s$i) { /**Call**/ /**Call**/
                                      double c$5 = index(s$i, s$a);
                                      /**eCall**/

                                      /**Call**/
                                      double c$6 = index(s$i, s$b);
                                      /**eCall**/
                                      double c$7 = sub(c$5, c$6);
                                      /**eCall**/
                                      return c$7;
  };
  vec<double> c$8 = build<double>(c$3, c$4);
  /**eCall**/
  return c$8;
}

double dot(vec<double> s$a, vec<double> s$b) {
  /**Ex**/
  /**Call**/
  vec<double> c$1 = mul$VecR$VecR(s$a, s$b);
  /**eCall**/
  auto c$0 = sum(c$1);
  /**eEx*/
  return c$0;
}

double sqnorm(vec<double> s$v) {
  /**Call**/
  double c$0 = dot(s$v, s$v);
  /**eCall**/
  return c$0;
}

vec<double> mul$Mat$Vec(vec<vec<double>> s$M, vec<double> s$v) {
  /**Call**/ /**Ex**/
  auto c$0 = size(s$M);
  /**eEx*/

  /**Lam**/ auto c$1 = [&](int s$i) { /**Call**/ /**Call**/
                                      vec<double> c$2 = index(s$i, s$M);
                                      /**eCall**/

                                      double c$3 = dot(c$2, s$v);
                                      /**eCall**/
                                      return c$3;
  };
  vec<double> c$4 = build<double>(c$0, c$1);
  /**eCall**/
  return c$4;
}

vec<vec<double>> gmm_knossos_makeQ(vec<double> s$q, vec<double> s$l) {
  /**Let**/ /**Ex**/
  auto c$0 = size(s$q);
  /**eEx*/
  int s$d = c$0;
  /**Call**/
  /**Lam**/ auto c$1 = [&](int s$i) {
    /**Call**/
    /**Lam**/ auto c$2 = [&](int s$j) { /**Call**/
                                        bool c$4 = lt(s$i, s$j);
                                        /**eCall**/
                                        double c$3;
                                        if (c$4) {
                                          ;
                                          c$3 = 0.0;
                                        } else {
                                          /**Call**/
                                          bool c$6 = eq(s$i, s$j);
                                          /**eCall**/
                                          double c$5;
                                          if (c$6) { /**Ex**/
                                            /**Call**/
                                            double c$8 = index(s$i, s$q);
                                            /**eCall**/
                                            auto c$7 = exp(c$8);
                                            /**eEx*/
                                            ;
                                            c$5 = c$7;
                                          } else {
                                            /**Call**/ /**Call**/ /**Ex**/
                                            /**Call**/
                                            int c$10 = sub(s$i, 1);
                                            /**eCall**/
                                            auto c$9 = gmm_knossos_tri(c$10);
                                            /**eEx*/

                                            int c$11 = add(c$9, s$j);
                                            /**eCall**/

                                            double c$12 = index(c$11, s$l);
                                            /**eCall**/
                                            ;
                                            c$5 = c$12;
                                          };
                                          c$3 = c$5;
                                        }
                                        return c$3;
    };
    vec<double> c$13 = build<double>(s$d, c$2);
    /**eCall**/
    return c$13;
  };
  vec<vec<double>> c$14 = build<vec<double>>(s$d, c$1);
  /**eCall**/
  return c$14;
}

double logsumexp(vec<double> s$v) {
  /**Ex**/
  /**Ex**/
  /**Ex**/
  auto c$2 = exp$VecR(s$v);
  /**eEx*/
  auto c$1 = sum(c$2);
  /**eEx*/
  auto c$0 = log(c$1);
  /**eEx*/
  return c$0;
}

double gmm_knossos_gmm_objective(vec<vec<double>> s$x, vec<double> s$alphas,
                                 vec<vec<double>> s$means,
                                 vec<vec<double>> s$qs, vec<vec<double>> s$ls,
                                 double s$wishart_gamma, double s$wishart_m) {
  /**Let**/ /**Ex**/
  auto c$0 = size(s$x);
  /**eEx*/
  int s$n = c$0;
  /**Let**/ /**Ex**/
  auto c$1 = size(s$alphas);
  /**eEx*/
  int s$K = c$1;
  /**Call**/ /**Call**/ /**Ex**/
                        /**Call**/
  /**Lam**/ auto c$3 = [&](int s$i) {
    /**Ex**/
    /**Call**/
    /**Lam**/ auto c$5 = [&](int s$k) {
      /**Let**/ /**Call**/
      vec<double> c$6 = index(s$k, s$qs);
      /**eCall**/
      vec<double> s$t31 = c$6;
      /**Call**/ /**Call**/ /**Call**/
      double c$7 = index(s$k, s$alphas);
      /**eCall**/

      /**Ex**/
      auto c$8 = sum(s$t31);
      /**eEx*/
      double c$9 = add(c$7, c$8);
      /**eCall**/

      /**Call**/
      /**Ex**/
      /**Call**/ /**Call**/
      /**Call**/
      vec<double> c$11 = index(s$k, s$ls);
      /**eCall**/
      vec<vec<double>> c$12 = gmm_knossos_makeQ(s$t31, c$11);
      /**eCall**/

      /**Call**/ /**Call**/
      vec<double> c$13 = index(s$i, s$x);
      /**eCall**/

      /**Call**/
      vec<double> c$14 = index(s$k, s$means);
      /**eCall**/
      vec<double> c$15 = sub$VecR$VecR(c$13, c$14);
      /**eCall**/
      vec<double> c$16 = mul$Mat$Vec(c$12, c$15);
      /**eCall**/
      auto c$10 = sqnorm(c$16);
      /**eEx*/
      double c$17 = mul(0.5, c$10);
      /**eCall**/
      double c$18 = sub(c$9, c$17);
      /**eCall**/
      return c$18;
    };
    vec<double> c$19 = build<double>(s$K, c$5);
    /**eCall**/
    auto c$4 = logsumexp(c$19);
    /**eEx*/
    return c$4;
  };
  vec<double> c$20 = build<double>(s$n, c$3);
  /**eCall**/
  auto c$2 = sum(c$20);
  /**eEx*/

  /**Call**/ /**Ex**/
  auto c$21 = to_float(s$n);
  /**eEx*/

  /**Ex**/
  auto c$22 = logsumexp(s$alphas);
  /**eEx*/
  double c$23 = mul(c$21, c$22);
  /**eCall**/
  double c$24 = sub(c$2, c$23);
  /**eCall**/

  /**Call**/
  /**Ex**/
  /**Call**/
  /**Lam**/ auto c$26 = [&](int s$k) { /**Call**/ /**Ex**/
                                       /**Ex**/
                                       /**Call**/
                                       vec<double> c$29 = index(s$k, s$qs);
                                       /**eCall**/
                                       auto c$28 = exp$VecR(c$29);
                                       /**eEx*/
                                       auto c$27 = sqnorm(c$28);
                                       /**eEx*/

                                       /**Ex**/
                                       /**Call**/
                                       vec<double> c$31 = index(s$k, s$ls);
                                       /**eCall**/
                                       auto c$30 = sqnorm(c$31);
                                       /**eEx*/
                                       double c$32 = add(c$27, c$30);
                                       /**eCall**/
                                       return c$32;
  };
  vec<double> c$33 = build<double>(s$K, c$26);
  /**eCall**/
  auto c$25 = sum(c$33);
  /**eEx*/
  double c$34 = mul(0.5, c$25);
  /**eCall**/
  double c$35 = add(c$24, c$34);
  /**eCall**/
  return c$35;
}

vec<double> mkvec(int s$n) {
  /**Call**/
  /**Lam**/ auto c$0 = [&](int s$j) { /**Call**/
                                      /**Call**/
                                      /**Ex**/
                                      auto c$1 = to_float(s$j);
                                      /**eEx*/
                                      double c$2 = add(1.0, c$1);
                                      /**eCall**/
                                      double c$3 = mul(2.0, c$2);
                                      /**eCall**/
                                      return c$3;
  };
  vec<double> c$4 = build<double>(s$n, c$0);
  /**eCall**/
  return c$4;
}

auto main() {
  /**Let**/                           /**Call**/
  /**Lam**/ auto c$0 = [&](int s$i) { /**Ex**/
                                      auto c$1 = mkvec(3);
                                      /**eEx*/
                                      return c$1;
  };
  vec<vec<double>> c$2 = build<vec<double>>(10, c$0);
  /**eCall**/
  vec<vec<double>> s$x = c$2;
  /**Let**/ /**Call**/
  /**Lam**/ auto c$3 = [&](int s$i) { return 7.0; };
  vec<double> c$4 = build<double>(10, c$3);
  /**eCall**/
  vec<double> s$alphas = c$4;
  /**Let**/                           /**Call**/
  /**Lam**/ auto c$5 = [&](int s$i) { /**Ex**/
                                      auto c$6 = mkvec(3);
                                      /**eEx*/
                                      return c$6;
  };
  vec<vec<double>> c$7 = build<vec<double>>(10, c$5);
  /**eCall**/
  vec<vec<double>> s$mus = c$7;
  /**Let**/                           /**Call**/
  /**Lam**/ auto c$8 = [&](int s$i) { /**Ex**/
                                      auto c$9 = mkvec(3);
                                      /**eEx*/
                                      return c$9;
  };
  vec<vec<double>> c$10 = build<vec<double>>(10, c$8);
  /**eCall**/
  vec<vec<double>> s$qs = c$10;
  /**Let**/                            /**Call**/
  /**Lam**/ auto c$11 = [&](int s$i) { /**Ex**/
                                       auto c$12 = mkvec(3);
                                       /**eEx*/
                                       return c$12;
  };
  vec<vec<double>> c$13 = build<vec<double>>(10, c$11);
  /**eCall**/
  vec<vec<double>> s$ls = c$13;
  /**Call**/ /**Call**/ /**Call**/ /**Call**/
  vec<double> c$14 = index(0, s$qs);
  /**eCall**/

  /**Call**/
  vec<double> c$15 = index(0, s$ls);
  /**eCall**/
  vec<vec<double>> c$16 = gmm_knossos_makeQ(c$14, c$15);
  /**eCall**/

  /**Call**/
  vec<double> c$17 = index(0, s$x);
  /**eCall**/
  vec<double> c$18 = mul$Mat$Vec(c$16, c$17);
  /**eCall**/

  /**Call**/

  double c$19 =
      gmm_knossos_gmm_objective(s$x, s$alphas, s$mus, s$qs, s$ls, 1.3, 1.2);
  /**eCall**/

  auto c$20 = pr(c$18, c$19, s$x, s$alphas, s$mus, s$qs, s$ls, 1.3, 1.2);
  /**eCall**/
  return c$20;
}

} // namespace ks
