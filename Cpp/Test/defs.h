#pragma once

#include <vector>
#include <string>

#include <Eigen\Dense>
#include <Eigen\StdVector>

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

//# Flexion, Abduction, Twist = 'xzy'
#define HAND_XYZ_TO_ROTATIONAL_PARAMETERIZATION {0, 2, 1} 