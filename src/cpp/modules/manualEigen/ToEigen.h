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

void read_hand_instance(const std::string& model_dir, const std::string& fn_in,
    std::vector<double>* theta, HandDataEigen* data, std::vector<double>* us = nullptr);

void read_hand_model(const std::string& path, HandModelEigen* pmodel);

//####################

void read_hand_model(const string& path, HandModelEigen* pmodel)
{
    const char DELIMITER = ':';
    auto& model = *pmodel;
    string fn_in = path + "bones.txt";
    std::ifstream bones_in(fn_in);
    if (!bones_in.good()) {
        std::cerr << "Cannot read " << fn_in << std::endl;
        throw "zoiks";
    }

    string s;
    while (bones_in.good())
    {
        getline(bones_in, s, DELIMITER);
        if (s.empty())
            continue;
        model.bone_names.push_back(s);
        getline(bones_in, s, DELIMITER);
        model.parents.push_back(std::stoi(s));
        double tmp[16];
        for (int i = 0; i < 16; i++)
        {
            getline(bones_in, s, DELIMITER);
            tmp[i] = std::stod(s);
        }
        model.base_relatives.push_back(Eigen::Map<Eigen::Matrix4d>(tmp));
        model.base_relatives.back().transposeInPlace();
        for (int i = 0; i < 15; i++)
        {
            getline(bones_in, s, DELIMITER);
            tmp[i] = std::stod(s);
        }
        getline(bones_in, s, '\n');
        tmp[15] = std::stod(s);
        model.inverse_base_absolutes.push_back(Eigen::Map<Eigen::Matrix4d>(tmp));
        model.inverse_base_absolutes.back().transposeInPlace();
    }
    bones_in.close();
    int n_bones = (int)model.bone_names.size();

    std::ifstream vert_in(path + "vertices.txt");
    int n_vertices = 0;
    while (vert_in.good())
    {
        getline(vert_in, s);
        if (!s.empty())
            n_vertices++;
    }
    vert_in.close();

    model.base_positions.resize(3, n_vertices);
    model.weights = Eigen::ArrayXXd::Zero(n_bones, n_vertices);
    vert_in = std::ifstream(path + "vertices.txt");
    for (int i_vert = 0; i_vert < n_vertices; i_vert++)
    {
        for (int j = 0; j < 3; j++)
        {
            getline(vert_in, s, DELIMITER);
            model.base_positions(j, i_vert) = std::stod(s);
        }
        for (int j = 0; j < 3 + 2; j++)
        {
            getline(vert_in, s, DELIMITER); // skip
        }
        getline(vert_in, s, DELIMITER);
        int n = std::stoi(s);
        for (int j = 0; j < n; j++)
        {
            getline(vert_in, s, DELIMITER);
            int i_bone = std::stoi(s);
            if (j == n - 1)
                getline(vert_in, s, '\n');
            else
                getline(vert_in, s, DELIMITER);
            model.weights(i_bone, i_vert) = std::stod(s);
        }
    }
    vert_in.close();

    std::ifstream triangles_in(path + "triangles.txt");
    string ss[3];
    while (triangles_in.good())
    {
        getline(triangles_in, ss[0], DELIMITER);
        if (ss[0].empty())
            continue;

        getline(triangles_in, ss[1], DELIMITER);
        getline(triangles_in, ss[2], '\n');
        Triangle curr;
        for (int i = 0; i < 3; i++)
            curr.verts[i] = std::stoi(ss[i]);
        model.triangles.push_back(curr);
    }
    triangles_in.close();

    model.is_mirrored = false;
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

