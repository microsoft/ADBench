// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include <vector>
#include <string>

#include <vnl\vnl_matrix.h>
#include <vnl\vnl_double_4x4.h>

#include <vnl/vnl_numeric_traits.h>

#include <adept_source.h>

using std::vector;
using std::string;
using adept::adouble;

template<typename T>
using vnl_matrix_4 = vnl_matrix_fixed<T, 4, 4>;

VCL_DEFINE_SPECIALIZATION
class vnl_numeric_traits<adouble>
{
public:
  //: Additive identity
  static VNL_EXPORT const adouble zero VCL_STATIC_CONST_INIT_FLOAT_DECL(0.0);
  //: Multiplicative identity
  static VNL_EXPORT const adouble one VCL_STATIC_CONST_INIT_FLOAT_DECL(1.0);
  //: Maximum value which this type can assume
  static VNL_EXPORT const adouble maxval VCL_STATIC_CONST_INIT_FLOAT_DECL(1.7976931348623157E+308);
  //: Return value of abs()
  typedef adouble abs_t;
  //: Name of a type twice as long as this one for accumulators and products.
  typedef adouble double_t;
  //: Name of type which results from multiplying this type with a double
  typedef adouble real_t;
};

#if !VCL_CANNOT_SPECIALIZE_CV
VCL_DEFINE_SPECIALIZATION
class vnl_numeric_traits<adouble const> : public vnl_numeric_traits<adouble> {};
#endif

namespace vnl_math {
  bool isnan(const adouble& x) { return false; } // hack
  bool isinf(const adouble& x) { return !_finite(x.value()) && !isnan(x); }
  bool isfinite(const adouble& x) { return _finite(x.value()) != 0; }
  inline adouble             abs(const adouble& x) { return x < 0.0 ? -x : x; }
  inline adouble             max(const adouble& x, const adouble& y) { return (x < y) ? y : x; }
  inline adouble             min(const adouble& x, const adouble& y) { return (x > y) ? y : x; }
  inline adouble             cube(const adouble& x) { return x*x*x; }
  inline int sgn(const adouble& x) { return (x != 0) ? ((x>0) ? 1 : -1) : 0; }
  inline int sgn0(const adouble& x) { return (x >= 0) ? 1 : -1; }
  inline adouble             sqr(const adouble& x) { return x*x; }
  inline adouble      squared_magnitude(const adouble&      x) { return x*x; }
}

#include <vnl\vnl_complex_traits.h>
VCL_DEFINE_SPECIALIZATION struct vnl_complex_traits<adouble>
{
  enum { isreal = true };
  static adouble conjugate(adouble x) { return x; }
  static vcl_complex<adouble> complexify(adouble x) { return vcl_complex<adouble>(x, 0.0); }
};

#include <vnl\vnl_matrix.txx>
VNL_MATRIX_INSTANTIATE(adept::adouble);
#include <vnl\vnl_c_vector.txx>
VNL_MATRIX_INSTANTIATE(adept::adouble);
#include <vnl\vnl_vector.txx>
VNL_MATRIX_INSTANTIATE(adept::adouble);

template <unsigned M, unsigned N, unsigned O>
vnl_matrix_fixed<adouble, M, O>
operator*(const vnl_matrix_fixed<adouble, M, N>& a, const vnl_matrix_fixed<double, N, O>& b)
{
  vnl_matrix_fixed<adouble, M, O> out;
  vnl_matrix_fixed_mat_mat_mult(a, b, &out);
  return out;
}

template <unsigned M, unsigned N, unsigned O>
vnl_matrix_fixed<adouble, M, O>
operator*(const vnl_matrix_fixed<double, M, N>& a, const vnl_matrix_fixed<adouble, N, O>& b)
{
  vnl_matrix_fixed<adouble, M, O> out;
  vnl_matrix_fixed_mat_mat_mult(a, b, &out);
  return out;
}

template<class T>
#include <vnl\vnl_matrix.txx>
void my_ordinary_mat_mult(vnl_matrix<double> const &A, vnl_matrix_4<T> const &B, vnl_matrix<T> &out)
{
  //out.set_size(A.rows(), B.cols());

  unsigned int l = A.rows();
  unsigned int m = A.cols(); // == B.num_rows
  unsigned int n = B.cols();

  for (unsigned int i = 0; i<l; ++i) {
    for (unsigned int k = 0; k<n; ++k) {
      T sum(0);
      for (unsigned int j = 0; j<m; ++j)
        sum = sum + A(i, j) * B(j, k);
      out(i, k) = sum;
    }
  }
}

//VNL_MATRIX_FIXED_INSTANTIATE(...)

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

void read_hand_model(const string& path, HandModelVXL *pmodel)
{
  const char DELIMITER = ':';
  auto& model = *pmodel;
  std::ifstream bones_in(path + "bones.txt");
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
    model.base_relatives.emplace_back();
    model.base_relatives.back().set(tmp);
    for (int i = 0; i < 15; i++)
    {
      getline(bones_in, s, DELIMITER);
      tmp[i] = std::stod(s);
    }
    getline(bones_in, s, '\n');
    tmp[15] = std::stod(s);
    model.inverse_base_absolutes.emplace_back();
    model.inverse_base_absolutes.back().set(tmp);
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

  model.base_positions.set_size(n_vertices, 4);
  model.base_positions.set_column(3, 1.);
  model.weights.set_size(n_bones, n_vertices);
  model.weights.fill(0.);
  vert_in = std::ifstream(path + "vertices.txt");
  for (int i_vert = 0; i_vert < n_vertices; i_vert++)
  {
    for (int j = 0; j < 3; j++)
    {
      getline(vert_in, s, DELIMITER);
      model.base_positions(i_vert, j) = std::stod(s);
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

  model.is_mirrored = false;
}

void read_hand_instance(const string& model_dir, const string& fn_in, 
  vector<double>* theta, HandDataVXL *data)
{
  read_hand_model(model_dir, &data->model);
  std::ifstream in(fn_in);
  int n_pts, n_theta;
  in >> n_pts >> n_theta;
  data->correspondences.resize(n_pts);
  data->points.set_size(n_pts, 3);
  for (int i = 0; i < n_pts; i++)
  {
    in >> data->correspondences[i];
    for (int j = 0; j < 3; j++)
    {
      in >> data->points(i, j);
    }
  }
  theta->resize(n_theta);
  for (int i = 0; i < n_theta; i++)
  {
    in >> (*theta)[i];
  }
  in.close();
}