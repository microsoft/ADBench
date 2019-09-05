#pragma once

#include <cstdlib>
#include <cmath>

#include "hand.h"

// Struct created by Tapenade for holding Matrix diff info.
typedef struct {
    double* data;
} Matrix_diff;



// Hand tracking function without us info differentiated by Tapenade in forward mode.
void hand_objective_d(
    const double* theta,
    const double* thetad,
    int bone_count,
    const char** bone_names,
    const int* parents,
    Matrix* base_relatives,
    Matrix* inverse_base_absolutes,
    Matrix* base_positions,
    Matrix* weights,
    const Triangle* triangles,
    int is_mirrored,
    int corresp_count,
    const int* correspondences,
    Matrix* points,
    double* err,
    double* errd
);



// Hand tracking function with us info differentiated by Tapenade in forward mode.
void hand_objective_us_d(
    const double* theta,
    const double* thetad,
    const double* us,
    const double* usd,
    int bone_count,
    const char** bone_names,
    const int* parents,
    Matrix* base_relatives,
    Matrix* inverse_base_absolutes,
    Matrix* base_positions,
    Matrix* weights,
    const Triangle* triangles,
    int is_mirrored,
    int corresp_count,
    const int* correspondences,
    Matrix* points,
    double* err,
    double* errd
);