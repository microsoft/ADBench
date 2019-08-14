#pragma once

#include "Eigen/Dense"

using Eigen::Map;

template<typename T>
using ArrayX = Eigen::Array<T, -1, 1>;

template<typename T>
using MapX = Eigen::Map<ArrayX<T>>;

template<typename T>
using MapConstX = Eigen::Map<const ArrayX<T>>;

template<typename T>
using ArrayX10 = Eigen::Array<T, -1, 10>;

template<typename T>
using MapX10 = Eigen::Map< Eigen::Array<T, -1, 10>>;

template<typename T>
using MapX8 = Eigen::Map< Eigen::Array<T, -1, 8>>;

template<typename T>
using MapX3 = Eigen::Map< Eigen::Array<T, -1, 3>>;

template<typename T>
using MapRow3 =  Eigen::Map<Eigen::Array<T, 1, 3>>;