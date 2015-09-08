#pragma once

#include <vector>
#include <string>

#include <Eigen\Dense>
#include <Eigen\StdVector>
#include <vnl\vnl_matrix.h>
#include <vnl\vnl_double_4x4.h>

using std::vector;
using std::string;

#ifndef NBDirsMax
#define NBDirsMax 1650
#endif

#define NBDirsMaxReproj_BV 2

#ifndef PI
#define PI 3.14159265359
#endif

typedef struct
{
  double gamma;
  int m;
} Wishart;

#define BA_NCAMPARAMS 11
#define BA_ROT_IDX 0
#define BA_C_IDX 3
#define BA_F_IDX 6
#define BA_X0_IDX 7
#define BA_RAD_IDX 9

template<typename T>
using avector = vector<T, Eigen::aligned_allocator<T>>;

typedef struct
{
  vector<string> bone_names;
  vector<int> parents; // assumimng that parent is earlier in the order of bones
  avector<Eigen::Matrix4d> base_relatives;
  avector<Eigen::Matrix4d> inverse_base_absolutes;
  Eigen::Matrix3Xd base_positions;
  Eigen::ArrayXXd weights;
  bool is_mirrored;
} HandModel;

typedef struct
{
  HandModel model;
  vector<int> correspondences;
  Eigen::Matrix3Xd points;
} HandData;

typedef vnl_matrix<double> vnl_matrix_d;
typedef struct
{
  vector<string> bone_names;
  vector<int> parents; // assumimng that parent is earlier in the order of bones
  vector<vnl_double_4x4> base_relatives;
  vector<vnl_double_4x4> inverse_base_absolutes;
  vnl_matrix_d base_positions; // X x 4
  vnl_matrix_d weights;
  bool is_mirrored;
} HandModelVXL;

typedef struct
{
  HandModelVXL model;
  vector<int> correspondences;
  vnl_matrix_d points; // X x 3
} HandDataVXL;

//# Flexion, Abduction, Twist = 'xzy'
#define HAND_XYZ_TO_ROTATIONAL_PARAMETERIZATION {0, 2, 1} 