#pragma warning(push)
#pragma warning(disable: 4244)
#pragma warning(disable: 4267)
#include <boost/numpy.hpp>
#include <boost/python/suite/indexing/vector_indexing_suite.hpp>
#pragma warning(pop)
#include "array_convert.h"

#include "poseinfer.h"

namespace bn = boost::numpy;
namespace bp = boost::python;
namespace pi = poseinfer;

// pi::vertex and pi::transform need equality operators to be wrapped in list types for Python
namespace poseinfer
{
	bool inline operator==(const vertex &lhs, const vertex &rhs)
	{
		for (int i = 0; i < vertex::Bases; ++i)
			if (lhs.bind_pos[i] != rhs.bind_pos[i]) return false;
		if (lhs.bind_n != rhs.bind_n) return false;
		if (lhs.uv != rhs.uv) return false;
		if (lhs.weights != rhs.weights) return false;
		if (lhs.bones != rhs.bones) return false;
		return true;
	}
}
namespace ts
{
	bool inline operator==(const pi::transform &lhs, const pi::transform &rhs)
	{
		auto rit = rhs.begin();
		for (auto lit = lhs.begin(); lit != lhs.end(); ++lit, ++rit)
		{
			if (*lit != *rit) return false;
		}
		return true;
	}
}

BOOST_PYTHON_MODULE(_poseinfer)
{
	bn::initialize();
	python_array_byvalue_converters<pi::vec2f, float, 2>();
	python_array_byvalue_converters<pi::vec3f, float, 3>();
	python_array_byvalue_converters<pi::shape, float, pi::vertex::Bases>();

	// poseinfer::model
	bp::class_<pi::model>("Model", bp::init<std::wstring>())
		.def("skeleton", &pi::model::skeleton, bp::return_internal_reference<1>())
		.def("vertices", &pi::model::vertices, bp::return_internal_reference<1>())
		;
	
	// poseinfer::pose
	bp::class_<std::vector<pi::transform>>("Pose")
		.def(bp::vector_indexing_suite<std::vector<pi::transform>>())
		;

	// poseinfer::pose_params
	void      (pi::pose_params::*set_global_scale      )(const pi::vec3f &)     = &pi::pose_params::global_scale;
	pi::vec3f (pi::pose_params::*get_global_scale      )(void)            const = &pi::pose_params::global_scale;
	void      (pi::pose_params::*set_global_rotation   )(const pi::vec3f &)     = &pi::pose_params::global_rotation;
	pi::vec3f (pi::pose_params::*get_global_rotation   )(void)            const = &pi::pose_params::global_rotation;
	void      (pi::pose_params::*set_global_translation)(const pi::vec3f &)     = &pi::pose_params::global_translation;
	pi::vec3f (pi::pose_params::*get_global_translation)(void)            const = &pi::pose_params::global_translation;
	void      (pi::pose_params::*set_joint_rotation)(size_t, const pi::vec3f &) = &pi::pose_params::joint_rotation;
	pi::vec3f (pi::pose_params::*get_joint_rotation)(size_t)              const = &pi::pose_params::joint_rotation;
	void      (pi::pose_params::*set_joint_scale_y) (size_t, float)             = &pi::pose_params::joint_scale_y;
	float     (pi::pose_params::*get_joint_scale_y) (size_t)              const = &pi::pose_params::joint_scale_y;
	bp::class_<pi::pose_params>("PoseParams", bp::init<size_t>())
		.add_property("global_scale",       get_global_scale      , set_global_scale      )
		.add_property("global_rotation",    get_global_rotation   , set_global_rotation   )
		.add_property("global_translation", get_global_translation, set_global_translation)
		.def("get_joint_rotation", get_joint_rotation)
		.def("set_joint_rotation", set_joint_rotation)
		.def("get_joint_scale_y", get_joint_scale_y)
		.def("set_joint_scale_y", set_joint_scale_y)
		;

	// poseinfer::skeleton
	pi::pose (pi::skeleton::*bind_to_world_withshape)(const pi::pose_params &, const pi::shape &) const = &pi::skeleton::bind_to_world_transforms;
	bp::class_<pi::skeleton>("Skeleton")
		.def("bind_to_world_transforms", bind_to_world_withshape)
		;

	// poseinfer::transform
	bp::class_<pi::transform>("Transform");

	// poseinfer::vertex
	pi::vec3f (*skinned_position_meanshape)(const pi::vertex &, const pi::pose &                   ) = &pi::skinned_position;
	pi::vec3f (*skinned_position_withshape)(const pi::vertex &, const pi::pose &, const pi::shape &) = &pi::skinned_position;
	bp::class_<pi::vertex>("Vertex")
		.def_readonly("Bases", &pi::vertex::Bases)
		.def("bind_position", &pi::bind_position)
		.def("skinned_position", skinned_position_withshape)
		;
	bp::class_<std::vector<pi::vertex>>("VertexList")
		.def(bp::vector_indexing_suite<std::vector<pi::vertex>>())
		;
}
