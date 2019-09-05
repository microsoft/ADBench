#include "TapenadeHand.h"

void TapenadeHand::prepare(HandInput&& input)
{
    this->input = input;
    complicated = this->input.us.size() > 0;

    if (objective_input != nullptr)
    {
        free_objective_input();
    }

    this->objective_input = convert_to_hand_objective_data(this->input);

    int err_size = 3 * this->input.data.correspondences.size();
    int ncols = this->input.theta.size();
    if (complicated)
    {
        ncols += 2;
    }

    result = {
        std::vector<double>(err_size),
        ncols,
        err_size,
        std::vector<double>(err_size * ncols)
    };

    theta_d = std::vector<double>(this->input.theta.size());
    us_d = std::vector<double>(this->input.us.size());
    us_jacobian_column = std::vector<double>(err_size);
}



HandOutput TapenadeHand::output()
{
    return result;
}



void TapenadeHand::calculate_objective(int times)
{
    if (complicated)
    {
        for (int i = 0; i < times; i++)
        {
            hand_objective_us(
                input.theta.data(),
                input.us.data(),
                objective_input->bone_count,
                objective_input->bone_names,
                objective_input->parents,
                objective_input->base_relatives,
                objective_input->inverse_base_absolutes,
                &objective_input->base_positions,
                &objective_input->weights,
                objective_input->triangles,
                objective_input->is_mirrored,
                objective_input->corresp_count,
                objective_input->correspondences,
                &objective_input->points,
                result.objective.data()
            );
        }
    }
    else
    {
        for (int i = 0; i < times; i++)
        {
            hand_objective(
                input.theta.data(),
                objective_input->bone_count,
                objective_input->bone_names,
                objective_input->parents,
                objective_input->base_relatives,
                objective_input->inverse_base_absolutes,
                &objective_input->base_positions,
                &objective_input->weights,
                objective_input->triangles,
                objective_input->is_mirrored,
                objective_input->corresp_count,
                objective_input->correspondences,
                &objective_input->points,
                result.objective.data()
            );
        }
    }
}



void TapenadeHand::calculate_jacobian(int times)
{
    if (complicated)
    {
        for (int i = 0; i < times; i++)
        {
            calculate_jacobian_complicated();
        }
    }
    else
    {
        for (int i = 0; i < times; i++)
        {
            calculate_jacobian_simple();
        }
    }
}



void TapenadeHand::calculate_jacobian_simple()
{
    for (int i = 0; i < theta_d.size(); i++)
    {
        if (i > 0)
        {
            theta_d[i - 1] = 0.0;
        }

        theta_d[i] = 1.0;
        hand_objective_d(
            input.theta.data(),
            theta_d.data(),
            objective_input->bone_count,
            objective_input->bone_names,
            objective_input->parents,
            objective_input->base_relatives,
            objective_input->inverse_base_absolutes,
            &objective_input->base_positions,
            &objective_input->weights,
            objective_input->triangles,
            objective_input->is_mirrored,
            objective_input->corresp_count,
            objective_input->correspondences,
            &objective_input->points,
            result.objective.data(),
            result.jacobian.data() + i * result.jacobian_nrows
        );
    }

    theta_d.back() = 0.0;
}



void TapenadeHand::calculate_jacobian_complicated()
{
    int nrows = result.objective.size();
    int shift = 2 * nrows;

    // calculate theta jacobian part
    for (int i = 0; i < theta_d.size(); i++)
    {
        if (i > 0)
        {
            theta_d[i - 1] = 0.0;
        }

        theta_d[i] = 1.0;
        hand_objective_us_d(
            input.theta.data(),
            theta_d.data(),
            input.us.data(),
            us_d.data(),
            objective_input->bone_count,
            objective_input->bone_names,
            objective_input->parents,
            objective_input->base_relatives,
            objective_input->inverse_base_absolutes,
            &objective_input->base_positions,
            &objective_input->weights,
            objective_input->triangles,
            objective_input->is_mirrored,
            objective_input->corresp_count,
            objective_input->correspondences,
            &objective_input->points,
            result.objective.data(),
            result.jacobian.data() + shift + i * nrows
        );
    }

    theta_d.back() = 0.0;

    // calculate us jacobian part
    for (int i = 0; i < us_d.size(); i++)
    {
        if (i > 0)
        {
            us_d[i - 1] = 0.0;
        }

        us_d[i] = 1.0;
        hand_objective_us_d(
            input.theta.data(),
            theta_d.data(),
            input.us.data(),
            us_d.data(),
            objective_input->bone_count,
            objective_input->bone_names,
            objective_input->parents,
            objective_input->base_relatives,
            objective_input->inverse_base_absolutes,
            &objective_input->base_positions,
            &objective_input->weights,
            objective_input->triangles,
            objective_input->is_mirrored,
            objective_input->corresp_count,
            objective_input->correspondences,
            &objective_input->points,
            result.objective.data(),
            us_jacobian_column.data()
        );

        if (i % 2 == 0)
        {
            for (int j = 0; j < 3; j++)
            {
                result.jacobian[3 * (i / 2) + j] = us_jacobian_column[3 * (i / 2) + j];
            }
        }
        else
        {
            for (int j = 0; j < 3; j++)
            {
                result.jacobian[nrows + 3 * ((i - 1) / 2) + j] = us_jacobian_column[3 * ((i - 1) / 2) + j];
            }
        }
    }

    us_d.back() = 0.0;
}



HandObjectiveData* TapenadeHand::convert_to_hand_objective_data(const HandInput& input)
{
    HandObjectiveData* result = new HandObjectiveData;

    result->correspondences = input.data.correspondences.data();
    result->corresp_count = input.data.correspondences.size();
    result->points = convert_to_matrix(input.data.points);

    const HandModelLightMatrix& imd = input.data.model;
    result->bone_count = imd.bone_names.size();
    result->parents = imd.parents.data();
    result->base_positions = convert_to_matrix(imd.base_positions);
    result->weights = convert_to_matrix(imd.weights);
    result->triangles = imd.triangles.data();
    result->is_mirrored = imd.is_mirrored ? 1 : 0;

    result->bone_names = new const char* [result->bone_count];
    result->base_relatives = new Matrix[result->bone_count];
    result->inverse_base_absolutes = new Matrix[result->bone_count];

    for (int i = 0; i < result->bone_count; i++)
    {
        result->bone_names[i] = imd.bone_names[i].data();
        result->base_relatives[i] = convert_to_matrix(imd.base_relatives[i]);
        result->inverse_base_absolutes[i] = convert_to_matrix(imd.inverse_base_absolutes[i]);
    }

    return result;
}



Matrix TapenadeHand::convert_to_matrix(const LightMatrix<double>& mat)
{
    return {
        mat.nrows_,
        mat.ncols_,
        mat.data_
    };
}



void TapenadeHand::free_objective_input()
{
    if (objective_input != nullptr)
    {
        delete[] objective_input->bone_names;
        delete[] objective_input->base_relatives;
        delete[] objective_input->inverse_base_absolutes;

        delete objective_input;
        objective_input = nullptr;
    }
}



extern "C" DLL_PUBLIC ITest<HandInput, HandOutput>* get_hand_test()
{
    return new TapenadeHand();
}