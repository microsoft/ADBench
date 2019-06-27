// ManualEigenHand.cpp : Defines the exported functions for the DLL.
#include "ManualEigenHand.h"
#include "../../shared/hand_eigen.h"
#include "hand_eigen_d.h"

#include <iostream>
#include <memory>

//
#include <Windows.h>
//

// This function must be called before any other function.
void ManualEigenHand::prepare(HandInput&& input)
{
    //_input = input;//
    _input.theta = input.theta;
    _input.us = input.us; //Should be = 0 in hand and != 0 in hand_complicated
    _input.data.correspondences = input.data.correspondences;
    Matrix3Xd _points(input.data.points.nrows_, input.data.points.ncols_);
    for (int i = 0; i < input.data.points.nrows_; i++)
    {
        for (int j = 0; j < input.data.points.ncols_; j++)
        {
            _points.row(i).col(j) << input.data.points.data_[i*j + j];
        }
    }
    _input.data.points = std::move(_points);
    ////*for (int i = 0; i < (sizeof(input.data.points.data_) / sizeof(*input.data.points.data_)); i++)
    //{
    //    _points << input.data.points.data_[i];
    //}*/
    ////*_points.col(0) << 1, 2, 3;
    //_points.col(0) << *input.data.points.get_col(0);*/
    ////_input.data.points.col(0) << 1;//input.data.points.get_col(0); //= input.data.points;//
    ////std::cerr << _input.data.points << std::endl;
    //std::cerr << _input.data.points << std::endl;
    //std::cout << _input.data.points << std::endl;
    ////OutputDebugStringW(L"sad",_input.data.points);
    //OutputDebugStringW(L"My output string.");
    //OutputDebugStringW(L"My output string.");
    //OutputDebugStringW(L"My output string.");
    //OutputDebugStringW(L"My output string.");
    ////input.data.points.nrows_ == 3; //  // input.data.points.size / input.data.points.cols == 3
    ////input.data.points.cols;
    ////
    //std::vector<std::string> bone_names;
    //std::vector<int> parents; // assumimng that parent is earlier in the order of bones
    //std::vector<LightMatrix<double>> base_relatives;
    //std::vector<LightMatrix<double>> inverse_base_absolutes;
    //LightMatrix<double> base_positions;
    //LightMatrix<double> weights;
    //std::vector<Triangle> triangles;
    //bool is_mirrored;

    //std::vector<std::string> bone_names;
    //std::vector<int> parents; // assumimng that parent is earlier in the order of bones
    //avector<Eigen::Matrix4d> base_relatives;
    //avector<Eigen::Matrix4d> inverse_base_absolutes;
    //Eigen::Matrix3Xd base_positions;
    //Eigen::ArrayXXd weights;
    //std::vector<Triangle> triangles;
    //bool is_mirrored;
    //////
    //int Jcols = (_input.k * (_input.d + 1) * (_input.d + 2)) / 2;
    //_output = { 0,  std::vector<double>(Jcols) };
}

HandOutput ManualEigenHand::output()
{
    return _output;
}

void ManualEigenHand::calculateObjective(int times)
{
    //for (int i = 0; i < times; ++i) {
    //    gmm_objective(_input.d, _input.k, _input.n, _input.alphas.data(), _input.means.data(),
    //        _input.icf.data(), _input.x.data(), _input.wishart, &_output.objective);
    //}
}

void ManualEigenHand::calculateJacobian(int times)
{
    //for (int i = 0; i < times; ++i) {
    //    gmm_objective_d(_input.d, _input.k, _input.n, _input.alphas.data(), _input.means.data(),
    //        _input.icf.data(), _input.x.data(), _input.wishart, &_output.objective, _output.gradient.data());
    //}
}

extern "C" __declspec(dllexport) ITest<HandInput, HandOutput>* __cdecl GetHandTest()
{
    return new ManualEigenHand();
}
