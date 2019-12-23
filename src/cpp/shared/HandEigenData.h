// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once 

#include "./hand_eigen_model.h"

#include <Eigen/Dense>
#include <Eigen/StdVector>

struct HandEigenInput
{
    std::vector<double> theta;
    HandDataEigen data;
    std::vector<double> us;
};

const Eigen::Map<Eigen::MatrixXd> inline convert_matrix(const LightMatrix<double>& lightmatrix)
{
    return Eigen::Map<Eigen::MatrixXd>(lightmatrix.data_, lightmatrix.nrows_, lightmatrix.ncols_);
};

void inline copy_HandInput_to_HandEigenInput(const HandInput& source, HandEigenInput& target)
{
    target.theta = source.theta;
    target.us = source.us;
    target.data.correspondences = source.data.correspondences;
    target.data.model.bone_names = source.data.model.bone_names;
    target.data.model.parents = source.data.model.parents;
    target.data.model.triangles = source.data.model.triangles;
    target.data.model.is_mirrored = source.data.model.is_mirrored;

    // Matrix& operator=(const DenseBase<OtherDerived>& other)
    // Copies the value of the expression other into *this with automatic resizing.
    target.data.points = convert_matrix(source.data.points);
    int n_vertices = source.data.model.base_positions.cols();
    target.data.model.base_positions.resize(3, n_vertices);
    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < n_vertices; j++)
        {
            target.data.model.base_positions(i, j) = source.data.model.base_positions(i, j);
        }
    }
    target.data.model.weights = convert_matrix(source.data.model.weights);

    for (int i = 0; i < source.data.model.base_relatives.size(); i++)
    {
        target.data.model.base_relatives.push_back(convert_matrix(source.data.model.base_relatives[i]));
    }
    for (int i = 0; i < source.data.model.inverse_base_absolutes.size(); i++)
    {
        target.data.model.inverse_base_absolutes.push_back(convert_matrix(source.data.model.inverse_base_absolutes[i]));
    }
}