#pragma once

#include "Eigen/Dense"

using Eigen::Map;

template<typename T>
using ArrayX = Eigen::Array<T, -1, 1>;

template<typename T>
using MapX = Eigen::Map<ArrayX<T>>;

template<typename T>
using MapConstX = Eigen::Map<const ArrayX<T>>;