// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include <Eigen/Dense>
#include <Eigen/StdVector>

#include "defs.h"

template<typename T>
using avector = std::vector<T, Eigen::aligned_allocator<T>>;

class HandModelEigen
{
public:
    std::vector<std::string> bone_names;
    std::vector<int> parents; // assumimng that parent is earlier in the order of bones
    avector<Eigen::Matrix4d> base_relatives;
    avector<Eigen::Matrix4d> inverse_base_absolutes;
    Eigen::Matrix3Xd base_positions;
    Eigen::ArrayXXd weights;
    std::vector<Triangle> triangles;
    bool is_mirrored;
};

class HandDataEigen
{
public:
    HandModelEigen model;
    std::vector<int> correspondences;
    Eigen::Matrix3Xd points;
};