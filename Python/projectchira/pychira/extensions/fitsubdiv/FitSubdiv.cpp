#pragma warning(disable: 4503) // decorated name length exceeded, name was truncated

#pragma warning(push)
#pragma warning(disable: 4244)
#pragma warning(disable: 4267)
#include <boost/numpy.hpp>
#include <boost/python/suite/indexing/vector_indexing_suite.hpp>
#pragma warning(pop)
#include "array_convert.h"

#include "poseinfer.h"
#include "fitsubdiv/energy.h"
#include "fitsubdiv/hierarchy.h"
#include "fitsubdiv/optimizer.h"
#include "fitsubdiv/poseinfer_interop.h"

namespace bn = boost::numpy;
namespace bp = boost::python;
namespace fs = fitsubdiv;
namespace pi = poseinfer;

static std::shared_ptr<fs::Model> load_fsmodel_via_pimodel(const std::wstring &folder, const bool is_right_hand)
{
	return std::make_shared<fs::Model>(fs::PoseInferInterop::from_poseinfer_model(pi::model(folder), is_right_hand));
}

static std::vector<fs::scalar> get_theta_from_poseparams(const fs::Model &model, const pi::pose_params &pose)
{
	std::vector<fs::scalar> theta;
	fs::PoseInferInterop::from_poseinfer_pose(model, pose, theta);
	return theta;
}

static pi::pose_params get_poseparams_from_theta(const fs::Model &model, const std::vector<fs::scalar> &theta)
{
	pi::pose_params pose(model.get_hierarchy()->get_n_bones());
	fs::PoseInferInterop::to_poseinfer_pose(model, theta, pose);
	return pose;
}

static std::shared_ptr<std::vector<fs::vec3>> vector_list_from_numpy(const bn::ndarray &array)
{
	if (array.get_nd() != 2) {
		PyErr_SetString(PyExc_TypeError, "Incorrect number of dimensions");
		bp::throw_error_already_set();
	}
	if (array.shape(1) != 3) {
		PyErr_SetString(PyExc_TypeError, "Incorrect array width");
		bp::throw_error_already_set();
	}
	if (array.get_dtype() != bn::dtype::get_builtin<double>()) {
		PyErr_SetString(PyExc_TypeError, "Incorrect array data type");
		bp::throw_error_already_set();
	}

	std::shared_ptr<std::vector<fs::vec3>> vec = std::make_shared<std::vector<fs::vec3>>(array.shape(0));

	char *data = array.get_data();
	Py_intptr_t const *strides = array.get_strides();
	for (unsigned int i = 0; i < array.shape(0); ++i)
	{
		for (unsigned int j = 0; j < 3; ++j)
		{
			double *ptr = reinterpret_cast<double *>(data + i * strides[0] + j * strides[1]);
			(*vec)[i][j] = static_cast<fs::scalar>(*ptr);
		}
	}

	return vec;
}

static fs::Optimizer::OptimizationResult optimize_wrapper(fs::Optimizer &optimizer, fs::State& state, bp::object iteration_callback)
{
	return optimizer.optimize(state, [&](fs::scalar time_in_ms, fs::scalar energy, const std::vector<fs::scalar> &theta, const std::vector<fastsubdiv::SurfaceCoordinate> &coordinates)
	{
		iteration_callback(time_in_ms, energy, theta, coordinates);
	});
}

// WeightedVertex and ModelPosition need equality operators to be wrapped as list types for Python
namespace fitsubdiv
{
	bool inline operator==(const Energy::ModelPosition::WeightedVertex &lhs, const Energy::ModelPosition::WeightedVertex &rhs)
	{
		return ((lhs.vertex_id == rhs.vertex_id) && (lhs.weight == rhs.weight));
	}
	bool inline operator!=(const Energy::ModelPosition::WeightedVertex &lhs, const Energy::ModelPosition::WeightedVertex &rhs)
	{
		return !(lhs == rhs);
	}

	bool inline operator==(const Energy::ModelPosition &lhs, const Energy::ModelPosition &rhs)
	{
		if (lhs.vertices.size() != rhs.vertices.size()) return false;
		for (int i = 0; i < lhs.vertices.size(); ++i)
		{
			if (lhs.vertices[i] != rhs.vertices[i]) return false;
		}
		return true;
	}
}

BOOST_PYTHON_MODULE(_fitsubdiv)
{
	bn::initialize();
	python_array_byvalue_converters<fs::vec3 , fs::scalar, 3>();

	bp::class_<fs::Model, std::shared_ptr<fs::Model>>("Model")
		.def("__init__", bp::make_constructor(load_fsmodel_via_pimodel))
		.def("get_theta", &get_theta_from_poseparams)
		.def("get_pose_params", &get_poseparams_from_theta)
		;

	bp::class_<std::vector<fs::scalar>>("Theta")
		.def(bp::vector_indexing_suite<std::vector<fs::scalar>>())
		;

	bp::class_<std::vector<std::vector<fs::scalar>>>("ThetaList")
		.def(bp::vector_indexing_suite<std::vector<std::vector<fs::scalar>>>())
		;

	bp::class_<std::vector<fs::vec3>, std::shared_ptr<std::vector<fs::vec3>>>("VectorList")
		.def("__init__", bp::make_constructor(vector_list_from_numpy))
		// Passing true to the NoProxy argument means that we can get at the items of the list by value if we want
		.def(bp::vector_indexing_suite<std::vector<fs::vec3>, true>())
		;

	bp::class_<fs::Options>("Options")
		.def_readwrite("n_iterations",                                    &fs::Options::n_iterations_)
		.def_readwrite("lambda_data_term",                                &fs::Options::lambda_data_term_)
		.def_readwrite("lambda_normal_term_",                             &fs::Options::lambda_normal_term_)
		.def_readwrite("lambda_bg_term_",                                 &fs::Options::lambda_bg_term_)
		.def_readwrite("lambda_beta_prior_",                              &fs::Options::lambda_beta_prior_)
		.def_readwrite("lambda_joint_limit_prior_",                       &fs::Options::lambda_joint_limit_prior_)
		.def_readwrite("lambda_pose_prior_",                              &fs::Options::lambda_pose_prior_)
		.def_readwrite("lambda_temporal_prior_",                          &fs::Options::lambda_temporal_prior_)
		.def_readwrite("lambda_target_term_",                             &fs::Options::lambda_target_term_)
		.def_readwrite("data_term_robustification_scale_in_cm_",          &fs::Options::data_term_robustification_scale_in_cm_)
		.def_readwrite("target_term_robustification_scale_in_cm_",        &fs::Options::target_term_robustification_scale_in_cm_)
		.def_readwrite("unknown_target_term_softmin_sigma_in_cm_",        &fs::Options::unknown_target_term_softmin_sigma_in_cm_)
		.def_readwrite("temporal_prior_robustification_scale_in_degrees", &fs::Options::temporal_prior_robustification_scale_in_degrees)
		;

	bp::class_<fs::Energy::ModelPosition::WeightedVertex>("WeightedVertex")
		.def_readwrite("vertex_id", &fs::Energy::ModelPosition::WeightedVertex::vertex_id)
		.def_readwrite("weight",    &fs::Energy::ModelPosition::WeightedVertex::weight)
		;
	bp::class_<std::vector<fs::Energy::ModelPosition::WeightedVertex>>("WeightedVertexList")
		.def(bp::vector_indexing_suite<std::vector<fs::Energy::ModelPosition::WeightedVertex>>())
		;
	bp::class_<fs::Energy::ModelPosition>("ModelPosition")
		.def_readwrite("vertices", &fs::Energy::ModelPosition::vertices)
		;
	bp::class_<std::vector<fs::Energy::ModelPosition>>("ModelPositionList")
		.def(bp::vector_indexing_suite<std::vector<fs::Energy::ModelPosition>>())
		;

	fs::scalar(fs::Energy::*evaluate_scalar)(const fs::State &, const bool& cancel) const = &fs::Energy::evaluate;
	bp::class_<fs::Energy, std::shared_ptr<fs::Energy>>("Energy",
		bp::init<std::shared_ptr<fs::Model>,
			     const std::vector<fs::vec3> &,
				 const std::vector<fs::vec3> &,
				 const fs::Options &>())
		.def("add_known_correspondence", &fs::Energy::add_known_correspondence)
		.def("add_unknown_correspondence", &fs::Energy::add_unknown_correspondence)
		.def("evaluate_scalar", evaluate_scalar)
		.def("make_state", &fs::Energy::make_state)
		;

	bp::class_<fs::State>("State")
		.def_readwrite("correspondences", &fs::State::correspondences_)
		.def_readwrite("thetas",          &fs::State::thetas_)
		.def_readwrite("timestamps",      &fs::State::time_stamps_)
		;

	bp::class_<fs::SampledCoordinatesSet, std::shared_ptr<fs::SampledCoordinatesSet>>("SampledCoordinatesSet",
		bp::init<const fs::Options &,
				 std::shared_ptr<fs::Model>>());

	bp::class_<fastsubdiv::SurfaceCoordinate>("SurfaceCoordinate")
		.def_readwrite("patch_index",      &fastsubdiv::SurfaceCoordinate::patch_index_)
		.def_readwrite("patch_coordinate", &fastsubdiv::SurfaceCoordinate::patch_coordinate_)
		;

	bp::class_<std::vector<fastsubdiv::SurfaceCoordinate>>("SurfaceCoordinateList")
		.def(bp::vector_indexing_suite<std::vector<fastsubdiv::SurfaceCoordinate>>())
		;

	bp::class_<fs::Optimizer>("Optimizer",
		bp::init<const fs::Options &,
				 std::shared_ptr<fs::Model>,
				 std::shared_ptr<fs::Energy>,
				 std::shared_ptr<fs::SampledCoordinatesSet>>())
		.def("optimize", &optimize_wrapper)
		;

	bp::class_<fs::Optimizer::OptimizationResult>("OptimizationResult")
		.def_readonly("final_energy",              &fs::Optimizer::OptimizationResult::final_energy_)
		.def_readonly("final_trust_region_radius", &fs::Optimizer::OptimizationResult::final_trust_region_radius_)
		;
}
