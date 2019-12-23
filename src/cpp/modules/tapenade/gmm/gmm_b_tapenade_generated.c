// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// See instructions how to generate this file in a header of "gmm.c"
/*        Generated by TAPENADE     (INRIA, Ecuador team)
    Tapenade 3.14 (r7259) - 18 Jan 2019 09:35
*/
#include <adBuffer.h>

/*
  Differentiation of arr_max in reverse (adjoint) mode:
   gradient     of useful results: *x arr_max
   with respect to varying inputs: *x
   Plus diff mem management of: x:in

 ==================================================================== 
                                UTILS                                 
 ==================================================================== */
// This throws error on n<1
void arr_max_b(int n, const double *x, double *xb, double arr_maxb) {
    int i;
    double m = x[0];
    double mb = 0.0;
    int branch;
    double arr_max;
    for (i = 1; i < n; ++i)
        if (m < x[i]) {
            m = x[i];
            pushControl1b(1);
        } else
            pushControl1b(0);
    mb = arr_maxb;
    for (i = n-1; i > 0; --i) {
        popControl1b(&branch);
        if (branch != 0) {
            xb[i] = xb[i] + mb;
            mb = 0.0;
        }
    }
    xb[0] = xb[0] + mb;
}

/* ==================================================================== 
                                UTILS                                 
 ==================================================================== */
// This throws error on n<1
double arr_max_nodiff(int n, const double *x) {
    int i;
    double m = x[0];
    for (i = 1; i < n; ++i)
        if (m < x[i])
            m = x[i];
    return m;
}

/*
  Differentiation of sqnorm in reverse (adjoint) mode:
   gradient     of useful results: *x sqnorm
   with respect to varying inputs: *x
   Plus diff mem management of: x:in
*/
// sum of component squares
void sqnorm_b(int n, const double *x, double *xb, double sqnormb) {
    int i;
    double res = x[0]*x[0];
    double resb = 0.0;
    double sqnorm;
    resb = sqnormb;
    for (i = n-1; i > 0; --i)
        xb[i] = xb[i] + 2*x[i]*resb;
    xb[0] = xb[0] + 2*x[0]*resb;
}

// sum of component squares
double sqnorm_nodiff(int n, const double *x) {
    int i;
    double res = x[0]*x[0];
    for (i = 1; i < n; ++i)
        res = res + x[i]*x[i];
    return res;
}

/*
  Differentiation of subtract in reverse (adjoint) mode:
   gradient     of useful results: *out *y
   with respect to varying inputs: *out *y
   Plus diff mem management of: out:in y:in
*/
// out = a - b
void subtract_b(int d, const double *x, const double *y, double *yb, double *
        out, double *outb) {
    int id;
    for (id = d-1; id > -1; --id) {
        yb[id] = yb[id] - outb[id];
        outb[id] = 0.0;
    }
}

// out = a - b
void subtract_nodiff(int d, const double *x, const double *y, double *out) {
    int id;
    for (id = 0; id < d; ++id)
        out[id] = x[id] - y[id];
}

/*
  Differentiation of log_sum_exp in reverse (adjoint) mode:
   gradient     of useful results: *x log_sum_exp
   with respect to varying inputs: *x
   Plus diff mem management of: x:in
*/
void log_sum_exp_b(int n, const double *x, double *xb, double log_sum_expb) {
    int i;
    double mx;
    double mxb;
    double tempb;
    double log_sum_exp;
    mx = arr_max_nodiff(n, x);
    double semx = 0.0;
    double semxb = 0.0;
    for (i = 0; i < n; ++i)
        semx = semx + exp(x[i] - mx);
    semxb = log_sum_expb/semx;
    mxb = log_sum_expb;
    for (i = n-1; i > -1; --i) {
        tempb = exp(x[i]-mx)*semxb;
        xb[i] = xb[i] + tempb;
        mxb = mxb - tempb;
    }
    arr_max_b(n, x, xb, mxb);
}

double log_sum_exp_nodiff(int n, const double *x) {
    int i;
    double mx;
    mx = arr_max_nodiff(n, x);
    double semx = 0.0;
    for (i = 0; i < n; ++i)
        semx = semx + exp(x[i] - mx);
    return log(semx) + mx;
}

double log_gamma_distrib_nodiff(double a, double p) {
    int j;
    float PI;
    double out = 0.25*p*(p-1)*log(PI);
    double arg1;
    float result1;
    for (j = 1; j < p+1; ++j) {
        arg1 = a + 0.5*(1-j);
        result1 = lgamma(arg1);
        out = out + result1;
    }
    return out;
}

/*
  Differentiation of log_wishart_prior in reverse (adjoint) mode:
   gradient     of useful results: log_wishart_prior
   with respect to varying inputs: *Qdiags *sum_qs *icf
   Plus diff mem management of: Qdiags:in sum_qs:in icf:in

 ======================================================================== 
                                MAIN LOGIC                                
 ======================================================================== */
void log_wishart_prior_b(int p, int k, Wishart wishart, const double *sum_qs, 
        double *sum_qsb, const double *Qdiags, double *Qdiagsb, const double *
        icf, double *icfb, double log_wishart_priorb) {
    int ik;
    int n = p + wishart.m + 1;
    int icf_sz = p*(p+1)/2;
    double C;
    float arg1;
    double result1;
    double out = 0;
    double outb = 0.0;
    double log_wishart_prior;
    for (ik = 0; ik < k; ++ik) {
        double frobenius;
        double result1;
        int arg1;
        double result2;
    }
    outb = log_wishart_priorb;
    *Qdiagsb = 0.0;
    *sum_qsb = 0.0;
    *icfb = 0.0;
    for (ik = k-1; ik > -1; --ik) {
        double frobenius;
        double frobeniusb;
        double result1;
        double result1b;
        int arg1;
        double result2;
        double result2b;
        frobeniusb = wishart.gamma*wishart.gamma*0.5*outb;
        sum_qsb[ik] = sum_qsb[ik] - wishart.m*outb;
        result1b = frobeniusb;
        result2b = frobeniusb;
        arg1 = icf_sz - p;
        sqnorm_b(arg1, &(icf[ik*icf_sz + p]), &(icfb[ik*icf_sz + p]), result2b
                );
        sqnorm_b(p, &(Qdiags[ik*p]), &(Qdiagsb[ik*p]), result1b);
    }
}

/* ======================================================================== 
                                MAIN LOGIC                                
 ======================================================================== */
double log_wishart_prior_nodiff(int p, int k, Wishart wishart, const double *
        sum_qs, const double *Qdiags, const double *icf) {
    int ik;
    int n = p + wishart.m + 1;
    int icf_sz = p*(p+1)/2;
    double C;
    float arg1;
    double result1;
    arg1 = 0.5*n;
    result1 = log_gamma_distrib_nodiff(arg1, p);
    C = n*p*(log(wishart.gamma)-0.5*log(2)) - result1;
    double out = 0;
    for (ik = 0; ik < k; ++ik) {
        double frobenius;
        double result1;
        int arg1;
        double result2;
        result1 = sqnorm_nodiff(p, &(Qdiags[ik*p]));
        arg1 = icf_sz - p;
        result2 = sqnorm_nodiff(arg1, &(icf[ik*icf_sz + p]));
        frobenius = result1 + result2;
        out = out + 0.5*wishart.gamma*wishart.gamma*frobenius - wishart.m*
            sum_qs[ik];
    }
    return out - k*C;
}

/*
  Differentiation of preprocess_qs in reverse (adjoint) mode:
   gradient     of useful results: *Qdiags *sum_qs *icf
   with respect to varying inputs: *icf
   Plus diff mem management of: Qdiags:in sum_qs:in icf:in
*/
void preprocess_qs_b(int d, int k, const double *icf, double *icfb, double *
        sum_qs, double *sum_qsb, double *Qdiags, double *Qdiagsb) {
    int ik, id;
    int icf_sz = d*(d+1)/2;
    for (ik = 0; ik < k; ++ik)
        for (id = 0; id < d; ++id) {
            double q = icf[ik*icf_sz + id];
            pushReal8(q);
        }
    for (ik = k-1; ik > -1; --ik) {
        for (id = d-1; id > -1; --id) {
            double q;
            double qb = 0.0;
            popReal8(&q);
            qb = exp(q)*Qdiagsb[ik*d+id];
            Qdiagsb[ik*d + id] = 0.0;
            qb = qb + sum_qsb[ik];
            icfb[ik*icf_sz + id] = icfb[ik*icf_sz + id] + qb;
        }
        sum_qsb[ik] = 0.0;
    }
}

void preprocess_qs_nodiff(int d, int k, const double *icf, double *sum_qs, 
        double *Qdiags) {
    int ik, id;
    int icf_sz = d*(d+1)/2;
    for (ik = 0; ik < k; ++ik) {
        sum_qs[ik] = 0.;
        for (id = 0; id < d; ++id) {
            double q = icf[ik*icf_sz + id];
            sum_qs[ik] = sum_qs[ik] + q;
            Qdiags[ik*d + id] = exp(q);
        }
    }
}

/*
  Differentiation of Qtimesx in reverse (adjoint) mode:
   gradient     of useful results: *out *Qdiag *x *ltri
   with respect to varying inputs: *out *Qdiag *x *ltri
   Plus diff mem management of: out:in Qdiag:in x:in ltri:in
*/
void Qtimesx_b(int d, const double *Qdiag, double *Qdiagb, const double *ltri,
        double *ltrib, const double *x, double *xb, double *out, double *outb)
{
    // strictly lower triangular part
    int i, j;
    int adFrom;
    int Lparamsidx = 0;
    for (i = 0; i < d; ++i) {
        adFrom = i + 1;
        for (j = adFrom; j < d; ++j)
            Lparamsidx++;
        pushInteger4(adFrom);
    }
    for (i = d-1; i > -1; --i) {
        popInteger4(&adFrom);
        for (j = d-1; j > adFrom-1; --j) {
            --Lparamsidx;
            ltrib[Lparamsidx] = ltrib[Lparamsidx] + x[i]*outb[j];
            xb[i] = xb[i] + ltri[Lparamsidx]*outb[j];
        }
    }
    for (i = d-1; i > -1; --i) {
        Qdiagb[i] = Qdiagb[i] + x[i]*outb[i];
        xb[i] = xb[i] + Qdiag[i]*outb[i];
        outb[i] = 0.0;
    }
}

void Qtimesx_nodiff(int d, const double *Qdiag, const double *ltri, const 
        double *x, double *out) {
    // strictly lower triangular part
    int i, j;
    for (i = 0; i < d; ++i)
        out[i] = Qdiag[i]*x[i];
    int Lparamsidx = 0;
    for (i = 0; i < d; ++i)
        for (j = i+1; j < d; ++j) {
            out[j] = out[j] + ltri[Lparamsidx]*x[i];
            Lparamsidx++;
        }
}

/*
  Differentiation of gmm_objective in reverse (adjoint) mode:
   gradient     of useful results: *err
   with respect to varying inputs: *err *means *icf *alphas
   RW status of diff variables: *err:in-out *means:out *icf:out
                *alphas:out
   Plus diff mem management of: err:in means:in icf:in alphas:in
*/
void gmm_objective_b(int d, int k, int n, const double *alphas, double *
        alphasb, const double *means, double *meansb, const double *icf, 
        double *icfb, const double *x, Wishart wishart, double *err, double *
        errb) {
    int ix, ik;
    float PI;
    const double CONSTANT = -n*d*0.5*log(2*PI);
    int icf_sz = d*(d+1)/2;
    double *Qdiags;
    double *Qdiagsb;
    double result1;
    double result1b;
    int ii1;
    Qdiagsb = (double *)malloc(d*k*sizeof(double));
    for (ii1 = 0; ii1 < d*k; ++ii1)
        Qdiagsb[ii1] = 0.0;
    Qdiags = (double *)malloc(d*k*sizeof(double));
    double *sum_qs;
    double *sum_qsb;
    sum_qsb = (double *)malloc(k*sizeof(double));
    for (ii1 = 0; ii1 < k; ++ii1)
        sum_qsb[ii1] = 0.0;
    sum_qs = (double *)malloc(k*sizeof(double));
    double *xcentered;
    double *xcenteredb;
    xcenteredb = (double *)malloc(d*sizeof(double));
    for (ii1 = 0; ii1 < d; ++ii1)
        xcenteredb[ii1] = 0.0;
    xcentered = (double *)malloc(d*sizeof(double));
    double *Qxcentered;
    double *Qxcenteredb;
    Qxcenteredb = (double *)malloc(d*sizeof(double));
    for (ii1 = 0; ii1 < d; ++ii1)
        Qxcenteredb[ii1] = 0.0;
    Qxcentered = (double *)malloc(d*sizeof(double));
    double *main_term;
    double *main_termb;
    main_termb = (double *)malloc(k*sizeof(double));
    for (ii1 = 0; ii1 < k; ++ii1)
        main_termb[ii1] = 0.0;
    main_term = (double *)malloc(k*sizeof(double));
    preprocess_qs_nodiff(d, k, icf, &(sum_qs[0]), &(Qdiags[0]));
    double slse = 0.;
    double slseb = 0.0;
    for (ix = 0; ix < n; ++ix)
        for (ik = 0; ik < k; ++ik) {
            pushReal8(xcentered[0]);
            subtract_nodiff(d, &(x[ix*d]), &(means[ik*d]), &(xcentered[0]));
            pushReal8(Qxcentered[0]);
            Qtimesx_nodiff(d, &(Qdiags[ik*d]), &(icf[ik*icf_sz + d]), &(
                           xcentered[0]), &(Qxcentered[0]));
            result1 = sqnorm_nodiff(d, &(Qxcentered[0]));
            pushReal8(main_term[ik]);
            main_term[ik] = alphas[ik] + sum_qs[ik] - 0.5*result1;
        }
    double lse_alphas;
    double lse_alphasb;
    slseb = *errb;
    lse_alphasb = -(n*(*errb));
    result1b = *errb;
    *errb = 0.0;
    log_wishart_prior_b(d, k, wishart, &(sum_qs[0]), &(sum_qsb[0]), &(Qdiags[0
                        ]), &(Qdiagsb[0]), icf, icfb, result1b);
    *alphasb = 0.0;
    log_sum_exp_b(k, alphas, alphasb, lse_alphasb);
    *meansb = 0.0;
    for (ix = n-1; ix > -1; --ix) {
        result1b = slseb;
        log_sum_exp_b(k, &(main_term[0]), &(main_termb[0]), result1b);
        for (ik = k-1; ik > -1; --ik) {
            popReal8(&(main_term[ik]));
            alphasb[ik] = alphasb[ik] + main_termb[ik];
            sum_qsb[ik] = sum_qsb[ik] + main_termb[ik];
            result1b = -(0.5*main_termb[ik]);
            main_termb[ik] = 0.0;
            sqnorm_b(d, &(Qxcentered[0]), &(Qxcenteredb[0]), result1b);
            popReal8(&(Qxcentered[0]));
            Qtimesx_b(d, &(Qdiags[ik*d]), &(Qdiagsb[ik*d]), &(icf[ik*icf_sz + 
                      d]), &(icfb[ik*icf_sz + d]), &(xcentered[0]), &(
                      xcenteredb[0]), &(Qxcentered[0]), &(Qxcenteredb[0]));
            popReal8(&(xcentered[0]));
            subtract_b(d, &(x[ix*d]), &(means[ik*d]), &(meansb[ik*d]), &(
                       xcentered[0]), &(xcenteredb[0]));
        }
    }
    preprocess_qs_b(d, k, icf, icfb, &(sum_qs[0]), &(sum_qsb[0]), &(Qdiags[0])
                    , &(Qdiagsb[0]));
    free(main_term);
    free(main_termb);
    free(Qxcentered);
    free(Qxcenteredb);
    free(xcentered);
    free(xcenteredb);
    free(sum_qs);
    free(sum_qsb);
    free(Qdiags);
    free(Qdiagsb);
}
