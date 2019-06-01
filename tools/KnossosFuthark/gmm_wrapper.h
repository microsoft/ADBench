#pragma once

/*
 * Headers
*/

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>


/*
 * Initialisation
*/

struct futhark_context_config ;
struct futhark_context_config *futhark_context_config_new();
void futhark_context_config_free(struct futhark_context_config *cfg);
void futhark_context_config_set_debugging(struct futhark_context_config *cfg,
                                          int flag);
void futhark_context_config_set_logging(struct futhark_context_config *cfg,
                                        int flag);
struct futhark_context ;
struct futhark_context *futhark_context_new(struct futhark_context_config *cfg);
void futhark_context_free(struct futhark_context *ctx);
int futhark_context_sync(struct futhark_context *ctx);
char *futhark_context_get_error(struct futhark_context *ctx);

/*
 * Arrays
*/

struct futhark_f64_1d ;
struct futhark_f64_1d *futhark_new_f64_1d(struct futhark_context *ctx,
                                          double *data, int64_t dim0);
struct futhark_f64_1d *futhark_new_raw_f64_1d(struct futhark_context *ctx,
                                              char *data, int offset,
                                              int64_t dim0);
int futhark_free_f64_1d(struct futhark_context *ctx,
                        struct futhark_f64_1d *arr);
int futhark_values_f64_1d(struct futhark_context *ctx,
                          struct futhark_f64_1d *arr, double *data);
char *futhark_values_raw_f64_1d(struct futhark_context *ctx,
                                struct futhark_f64_1d *arr);
int64_t *futhark_shape_f64_1d(struct futhark_context *ctx,
                              struct futhark_f64_1d *arr);
struct futhark_f64_2d ;
struct futhark_f64_2d *futhark_new_f64_2d(struct futhark_context *ctx,
                                          double *data, int64_t dim0,
                                          int64_t dim1);
struct futhark_f64_2d *futhark_new_raw_f64_2d(struct futhark_context *ctx,
                                              char *data, int offset,
                                              int64_t dim0, int64_t dim1);
int futhark_free_f64_2d(struct futhark_context *ctx,
                        struct futhark_f64_2d *arr);
int futhark_values_f64_2d(struct futhark_context *ctx,
                          struct futhark_f64_2d *arr, double *data);
char *futhark_values_raw_f64_2d(struct futhark_context *ctx,
                                struct futhark_f64_2d *arr);
int64_t *futhark_shape_f64_2d(struct futhark_context *ctx,
                              struct futhark_f64_2d *arr);

/*
 * Opaque values
*/


/*
 * Entry points
*/

int futhark_entry_rev_gmm_objective(struct futhark_context *ctx,
                                    struct futhark_f64_1d **out0,
                                    struct futhark_f64_2d **out1,
                                    struct futhark_f64_2d **out2,
                                    struct futhark_f64_2d **out3, const
                                    struct futhark_f64_2d *in0, const
                                    struct futhark_f64_1d *in1, const
                                    struct futhark_f64_2d *in2, const
                                    struct futhark_f64_2d *in3, const
                                    struct futhark_f64_2d *in4, const
                                    double in5, const int32_t in6, const
                                    double in7);
int futhark_entry_gmm_objective(struct futhark_context *ctx, double *out0, const
                                struct futhark_f64_2d *in0, const
                                struct futhark_f64_1d *in1, const
                                struct futhark_f64_2d *in2, const
                                struct futhark_f64_2d *in3, const
                                struct futhark_f64_2d *in4, const double in5,
                                const int32_t in6);

/*
 * Miscellaneous
*/

void futhark_debugging_report(struct futhark_context *ctx);
