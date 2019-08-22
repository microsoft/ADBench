#pragma once

#include "../../shared/ITest.h"
#include "../../shared/BAData.h"
#include "../../shared/defs.h"

#include "ba.h"
#include "ba_d.h"

#include <vector>

class TapenadeBA : public ITest<BAInput, BAOutput>
{
private:
    BAInput input;
    BAOutput result;
    std::vector<double> state;

    // buffers for holding differentitation directions
    std::vector<double> cam_d;
    std::vector<double> x_d;
    std::vector<double> w_d;

    // buffer for reprojection error jacobian part holding
    std::vector<double> reproj_err_d;

public:
    // This function must be called before any other function.
    virtual void prepare(BAInput&& input) override;

    virtual void calculate_objective(int times) override;
    virtual void calculate_jacobian(int times) override;
    virtual BAOutput output() override;

    ~TapenadeBA() {}

private:
    void compute_jacobian_reproj_block(int block);
    void compute_jacobian_columns(int block, int shift, std::vector<double>& direction);
};

