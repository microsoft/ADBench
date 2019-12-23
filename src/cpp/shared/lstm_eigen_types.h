// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include "Eigen/Dense"

using Eigen::Map;

//Dynamic sized column array
template<typename T>
using ArrayX = Eigen::Array<T, -1, 1>;

template<typename T>
using MapX = Eigen::Map<ArrayX<T>>;

template<typename T>
using MapConstX = Eigen::Map<const ArrayX<T>>;

//Map of array with X rows and 10 cols
template<typename T>
using MapX10 = Eigen::Map< Eigen::Array<T, -1, 10>>;

//Map of array with X rows and 8 cols
template<typename T>
using MapX8 = Eigen::Map< Eigen::Array<T, -1, 8>>;

//Map of array with X rows and 3 cols
template<typename T>
using MapX3 = Eigen::Map< Eigen::Array<T, -1, 3>>;

//3 elements in row array map
template<typename T>
using MapRow3 =  Eigen::Map<Eigen::Array<T, 1, 3>>;