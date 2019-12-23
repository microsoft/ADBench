// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include <vector>

#include "../../shared/ITest.h"
#include "../../shared/HandData.h"
#include "../../shared/light_matrix.h"
#include "../../shared/defs.h"

#include "hand/hand.h"
#include "hand/hand_d.h"

// Data for hand objective converted from input
struct HandObjectiveData
{
    int bone_count;
    const char** bone_names;
    const int* parents;             // assumimng that parent is earlier in the order of bones
    Matrix* base_relatives;
    Matrix* inverse_base_absolutes;
    Matrix base_positions;
    Matrix weights;
    const Triangle* triangles;
    int is_mirrored;
    int corresp_count;
    const int* correspondences;
    Matrix points;
};



class TapenadeHand : public ITest<HandInput, HandOutput> {
    HandObjectiveData* objective_input = nullptr;
    HandInput input;
    HandOutput result;
    bool complicated = false;

    std::vector<double> theta_d;                // buffer for theta differentiation directions
    std::vector<double> us_d;                   // buffer for us differentiation directions

    std::vector<double> us_jacobian_column;     // buffer for holding jacobian column while differentiating by us

public:
    // This function must be called before any other function.
    void prepare(HandInput&& input) override;

    void calculate_objective(int times) override;
    void calculate_jacobian(int times) override;
    HandOutput output() override;

    ~TapenadeHand() { free_objective_input(); }

private:
    static HandObjectiveData* convert_to_hand_objective_data(const HandInput& input);
    static Matrix convert_to_matrix(const LightMatrix<double>& mat);

    void free_objective_input();
    void calculate_jacobian_simple();
    void calculate_jacobian_complicated();
};