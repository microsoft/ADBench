#pragma once

#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <functional>

//#ifdef DO_EIGEN
#include <Eigen/Dense>
#include <Eigen/StdVector>
//#endif

#include "../../shared/light_matrix.h"

#include "../../shared/defs.h"

template<typename T>
using avector = std::vector<T, Eigen::aligned_allocator<T>>;

typedef struct
{
    std::vector<std::string> bone_names;
    std::vector<int> parents; // assumimng that parent is earlier in the order of bones
    avector<Eigen::Matrix4d> base_relatives;
    avector<Eigen::Matrix4d> inverse_base_absolutes;
    Eigen::Matrix3Xd base_positions;
    Eigen::ArrayXXd weights;
    std::vector<Triangle> triangles;
    bool is_mirrored;
} HandModelEigen;

typedef struct
{
    HandModelEigen model;
    std::vector<int> correspondences;
    Eigen::Matrix3Xd points;
} HandDataEigen;

class HandModelLightMatrix
{
public:
    std::vector<std::string> bone_names;
    std::vector<int> parents; // assumimng that parent is earlier in the order of bones
    std::vector<LightMatrix<double>> base_relatives;
    std::vector<LightMatrix<double>> inverse_base_absolutes;
    LightMatrix<double> base_positions;
    LightMatrix<double> weights;
    std::vector<Triangle> triangles;
    bool is_mirrored;
};

class HandDataLightMatrix
{
public:
    HandModelLightMatrix model;
    std::vector<int> correspondences;
    LightMatrix<double> points;
};

void read_hand_instance(const std::string& model_dir, const std::string& fn_in,
    std::vector<double>* theta, HandDataLightMatrix* data, std::vector<double>* us = nullptr);

void read_hand_instance(const std::string& model_dir, const std::string& fn_in,
    std::vector<double>* theta, HandDataEigen* data, std::vector<double>* us = nullptr);

//####################

void read_hand_instance(const string& model_dir, const string& fn_in,
    vector<double>* theta, HandDataLightMatrix* data, vector<double>* us)
{
    read_hand_model(model_dir, &data->model);
    std::ifstream in(fn_in);
    int n_pts, n_theta;
    in >> n_pts >> n_theta;
    data->correspondences.resize(n_pts);
    data->points.resize(3, n_pts);
    for (int i = 0; i < n_pts; i++)
    {
        in >> data->correspondences[i];
        for (int j = 0; j < 3; j++)
        {
            in >> data->points(j, i);
        }
    }
    if (us != nullptr)
    {
        us->resize(2 * n_pts);
        for (int i = 0; i < 2 * n_pts; i++)
        {
            in >> (*us)[i];
        }
    }
    theta->resize(n_theta);
    for (int i = 0; i < n_theta; i++)
    {
        in >> (*theta)[i];
    }
    in.close();
}

void read_hand_instance(const string& model_dir, const string& fn_in,
    vector<double>* theta, HandDataEigen* data, vector<double>* us)
{
    read_hand_model(model_dir, &data->model);
    std::ifstream in(fn_in);
    if (!in.good()) {
        std::cerr << "Cannot read " << fn_in << std::endl;
        throw "zoiks";
    }
    int n_pts, n_theta;
    in >> n_pts >> n_theta;
    std::cout << "read_hand_instance: npts = " << n_pts << ", n_theta = " << n_theta << std::endl;
    data->correspondences.resize(n_pts);
    data->points.resize(3, n_pts);
    for (int i = 0; i < n_pts; i++)
    {
        in >> data->correspondences[i];
        for (int j = 0; j < 3; j++)
        {
            in >> data->points(j, i);
        }
    }
    if (us != nullptr)
    {
        us->resize(2 * n_pts);
        for (int i = 0; i < 2 * n_pts; i++)
        {
            in >> (*us)[i];
        }
    }
    theta->resize(n_theta);
    for (int i = 0; i < n_theta; i++)
    {
        in >> (*theta)[i];
    }
    if (!in.good()) {
        std::cerr << "Cannot read " << fn_in << std::endl;
        throw "zoiks";
    }
    in.close();
}

