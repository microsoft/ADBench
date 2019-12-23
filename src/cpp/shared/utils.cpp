// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "utils.h"

#pragma warning (disable : 4996) // fopen

#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <functional>
#include <limits>
#include <chrono>
#include <cstring>

#ifdef DO_EIGEN
#include <Eigen/Dense>
#include <Eigen/StdVector>
#endif

#include "light_matrix.h"

#include "defs.h"

using std::cin;
using std::cout;
using std::endl;
using std::string;
using std::vector;
using std::getline;
using std::memcpy;
using namespace std::chrono;

BASparseMat::BASparseMat() {}

BASparseMat::BASparseMat(int n_, int m_, int p_) : n(n_), m(m_), p(p_)
{
    nrows = 2 * p + p;
    ncols = BA_NCAMPARAMS * n + 3 * m + p;
    rows.reserve(nrows + 1);
    int nnonzero = (BA_NCAMPARAMS + 3 + 1) * 2 * p + p;
    cols.reserve(nnonzero);
    vals.reserve(nnonzero);
    rows.push_back(0);
}

void BASparseMat::insert_reproj_err_block(int obsIdx,
    int camIdx, int ptIdx, const double* const J)
{
    int n_new_cols = BA_NCAMPARAMS + 3 + 1;
    rows.push_back(rows.back() + n_new_cols);
    rows.push_back(rows.back() + n_new_cols);

    for (int i_row = 0; i_row < 2; i_row++)
    {
        for (int i = 0; i < BA_NCAMPARAMS; i++)
        {
            cols.push_back(BA_NCAMPARAMS * camIdx + i);
            vals.push_back(J[2 * i + i_row]);
        }
        int col_offset = BA_NCAMPARAMS * n;
        int val_offset = BA_NCAMPARAMS * 2;
        for (int i = 0; i < 3; i++)
        {
            cols.push_back(col_offset + 3 * ptIdx + i);
            vals.push_back(J[val_offset + 2 * i + i_row]);
        }
        col_offset += 3 * m;
        val_offset += 3 * 2;
        cols.push_back(col_offset + obsIdx);
        vals.push_back(J[val_offset + i_row]);
    }
}

void BASparseMat::insert_w_err_block(int wIdx, double w_d)
{
    rows.push_back(rows.back() + 1);
    cols.push_back(BA_NCAMPARAMS * n + 3 * m + wIdx);
    vals.push_back(w_d);
}

void BASparseMat::clear()
{
    rows.clear();
    cols.clear();
    vals.clear();
    rows.reserve(nrows + 1);
    int nnonzero = (BA_NCAMPARAMS + 3 + 1) * 2 * p + p;
    cols.reserve(nnonzero);
    vals.reserve(nnonzero);
    rows.push_back(0);
}


void read_gmm_instance(const string& fn,
    int* d, int* k, int* n,
    vector<double>& alphas,
    vector<double>& means,
    vector<double>& icf,
    vector<double>& x,
    Wishart& wishart,
    bool replicate_point)
{
    FILE* fid = fopen(fn.c_str(), "r");

    if (!fid) {
        std::cerr << "Cannot open " << fn << std::endl;
        throw "oiks";
    }

    fscanf(fid, "%i %i %i", d, k, n);

    int d_ = *d, k_ = *k, n_ = *n;

    int icf_sz = d_ * (d_ + 1) / 2;
    alphas.resize(k_);
    means.resize(d_ * k_);
    icf.resize(icf_sz * k_);
    x.resize(d_ * n_);

    for (int i = 0; i < k_; i++)
    {
        fscanf(fid, "%lf", &alphas[i]);
    }

    for (int i = 0; i < k_; i++)
    {
        for (int j = 0; j < d_; j++)
        {
            fscanf(fid, "%lf", &means[i * d_ + j]);
        }
    }

    for (int i = 0; i < k_; i++)
    {
        for (int j = 0; j < icf_sz; j++)
        {
            fscanf(fid, "%lf", &icf[i * icf_sz + j]);
        }
    }

    if (replicate_point)
    {
        for (int j = 0; j < d_; j++)
        {
            fscanf(fid, "%lf", &x[j]);
        }
        for (int i = 0; i < n_; i++)
        {
            memcpy(&x[i * d_], &x[0], d_ * sizeof(double));
        }
    }
    else
    {
        for (int i = 0; i < n_; i++)
        {
            for (int j = 0; j < d_; j++)
            {
                fscanf(fid, "%lf", &x[i * d_ + j]);
            }
        }
    }

    fscanf(fid, "%lf %i", &(wishart.gamma), &(wishart.m));

    fclose(fid);
}

void read_ba_instance(const string& fn,
    int& n, int& m, int& p,
    vector<double>& cams,
    vector<double>& X,
    vector<double>& w,
    vector<int>& obs,
    vector<double>& feats)
{
    FILE* fid = fopen(fn.c_str(), "r");
    if (!fid) {
        throw "oik" + fn;
    }
    std::cout << "read_ba_instance: opened " << fn << std::endl;

    fscanf(fid, "%i %i %i", &n, &m, &p);
    int nCamParams = 11;

    cams.resize(nCamParams * n);
    X.resize(3 * m);
    w.resize(p);
    obs.resize(2 * p);
    feats.resize(2 * p);

    for (int j = 0; j < nCamParams; j++)
        fscanf(fid, "%lf", &cams[j]);
    for (int i = 1; i < n; i++)
        memcpy(&cams[i * nCamParams], &cams[0], nCamParams * sizeof(double));

    for (int j = 0; j < 3; j++)
        fscanf(fid, "%lf", &X[j]);
    for (int i = 1; i < m; i++)
        memcpy(&X[i * 3], &X[0], 3 * sizeof(double));

    fscanf(fid, "%lf", &w[0]);
    for (int i = 1; i < p; i++)
        w[i] = w[0];

    int camIdx = 0;
    int ptIdx = 0;
    for (int i = 0; i < p; i++)
    {
        obs[i * 2 + 0] = (camIdx++ % n);
        obs[i * 2 + 1] = (ptIdx++ % m);
    }

    fscanf(fid, "%lf %lf", &feats[0], &feats[1]);
    for (int i = 1; i < p; i++)
    {
        feats[i * 2 + 0] = feats[0];
        feats[i * 2 + 1] = feats[1];
    }

    fclose(fid);
}

void write_J_sparse(const string& fn, const BASparseMat& J)
{
    write_J_stream<decltype(J.vals)::value_type> out(fn, J.nrows, J.ncols);

    out << J.rows.size() << endl;
    for (size_t i = 0; i < J.rows.size(); i++)
    {
        out << J.rows[i] << " ";
    }
    out << endl;
    out << J.cols.size() << endl;
    for (size_t i = 0; i < J.cols.size(); i++)
    {
        out << J.cols[i] << " ";
    }
    out << endl;
    for (size_t i = 0; i < J.vals.size(); i++)
    {
        out << J.vals[i] << " ";
    }
    out.close();
}

void write_J(const string& fn, int Jrows, int Jcols, double** J)
{
    write_J_stream<decltype(**J)> out(fn, Jrows, Jcols);

    for (int i = 0; i < Jrows; i++)
    {
        for (int j = 0; j < Jcols; j++)
        {
            out << J[i][j] << " ";
        }
        out << endl;
    }
    out.close();
}

void write_J(const string& fn, int Jrows, int Jcols, double* J)
{
    write_J_stream<decltype(*J)> out(fn, Jrows, Jcols);

    for (int i = 0; i < Jrows; i++)
    {
        for (int j = 0; j < Jcols; j++)
        {
            out << J[j * Jrows + i] << " ";
        }
        out << endl;
    }
    out.close();
}

void write_times(double tf, double tJ)
{
    cout << "tf = " << std::scientific << tf << "s" << endl;
    cout << "tJ = " << tJ << "s" << endl;
    cout << "tJ/tf = " << tJ / tf << "s" << endl;
}

void write_times(const string& fn, double tf, double tJ, double* t_sparsity)
{
    std::ofstream out(fn);
    out << std::scientific << tf << " " << tJ;
    if (t_sparsity)
        out << " " << *t_sparsity;
    out << endl;
    out << "tf tJ";
    if (t_sparsity)
        out << " t_sparsity";
    out << endl;
    out << "tf = " << std::scientific << tf << "s" << endl;
    out << "tJ = " << tJ << "s" << endl;
    out << "tJ/tf = " << tJ / tf << "s" << endl;
    out.close();
}

#ifdef DO_EIGEN
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
#endif

void read_hand_model(const string& path, HandModelLightMatrix* pmodel)
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
        model.base_relatives.emplace_back(4, 4);
        model.base_relatives.back().set(tmp);
        model.base_relatives.back().transpose_in_place();
        for (int i = 0; i < 15; i++)
        {
            getline(bones_in, s, DELIMITER);
            tmp[i] = std::stod(s);
        }
        getline(bones_in, s, '\n');
        tmp[15] = std::stod(s);
        model.inverse_base_absolutes.emplace_back(4, 4);
        model.inverse_base_absolutes.back().set(tmp);
        model.inverse_base_absolutes.back().transpose_in_place();
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

    model.base_positions.resize(4, n_vertices);
    model.base_positions.set_row(3, 1.);
    model.weights.resize(n_bones, n_vertices);
    model.weights.fill(0.);
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

void read_lstm_instance(const string& fn,
    int* l, int* c, int* b,
    vector<double>& main_params,
    vector<double>& extra_params,
    vector<double>& state,
    vector<double>& sequence)
{
    FILE* fid = fopen(fn.c_str(), "r");

    if (!fid) {
        std::cerr << "Cannot open " << &fn << std::endl;
        throw "oiks";
    }

    fscanf(fid, "%i %i %i", l, c, b);

    int l_ = *l, c_ = *c, b_ = *b;

    int main_sz = 2 * l_ * 4 * b_;
    int extra_sz = 3 * b_;
    int state_sz = 2 * l_ * b_;
    int seq_sz = c_ * b_;

    main_params.resize(main_sz);
    extra_params.resize(extra_sz);
    state.resize(state_sz);
    sequence.resize(seq_sz);

    for (int i = 0; i < main_sz; i++) {
        fscanf(fid, "%lf", &main_params[i]);
    }

    for (int i = 0; i < extra_sz; i++) {
        fscanf(fid, "%lf", &extra_params[i]);
    }

    for (int i = 0; i < state_sz; i++) {
        fscanf(fid, "%lf", &state[i]);
    }

    for (int i = 0; i < c_ * b_; i++) {
        fscanf(fid, "%lf", &sequence[i]);
    }

    /*char ch;
    fscanf(fid, "%c", &ch);
    fscanf(fid, "%c", &ch);

    for (int i = 0; i < c_; i++) {
        unsigned char ch;
        fscanf(fid, "%c", &ch);
        int cb = ch;
        for (int j = b_ - 1; j >= 0; j--) {
            int p = pow(2, j);
            if (cb >= p) {
                sequence[(i + 1) * b_ - j - 1] = 1;
                cb -= p;
            }
            else {
                sequence[(i + 1) * b_ - j - 1] = 0;
            }
        }
    }*/

    fclose(fid);
}

// Time a function
double timer(int nruns, double limit, std::function<void()> func) {
    if (limit < 0) limit = std::numeric_limits<double>::max();

    double total = 0;
    int i = 0;

    high_resolution_clock::time_point start = high_resolution_clock::now();
    for (; i < nruns && total < limit; ++i) {
        func();
        high_resolution_clock::time_point end = high_resolution_clock::now();
        total = duration_cast<duration<double>>(end - start).count();
    }

    if (i < nruns) std::cout << "Hit time limit after " << i << " loops" << endl;

    if (i > 0)
        return total / i;
    else
        return 0;
}
