#pragma warning(push)
#pragma warning(disable: 4244)
#include <boost/numpy.hpp>
#pragma warning(pop)

#include "Initialize.h"
#include "RecordedDataset.h"
#include "fitsubdiv/pre_processor.h"

namespace bn = boost::numpy;
namespace bp = boost::python;
namespace fs = fitsubdiv;
namespace pi = poseinfer;
using namespace ChiraTest::Recordings;

template <typename _TyImg>
static bn::ndarray image_object_to_ndarray(const bp::object &self)
{
	// Must be by reference: we mustn't create a copy here as it will go out of scope
	_TyImg &img = bp::extract<_TyImg &>(self)();

	// Construct an ndarray which points at the image data instead of taking a copy
	// The owner of the ndarray is set as the image object... i.e. the lifetime of
	// the returned array should be tied to the lifetime of the image
	return bn::from_data(img.data(),
						 bn::dtype::get_builtin<_TyImg::value_type>(),
						 bp::make_tuple(img.height(), img.width()),
						 bp::make_tuple(img.stride_bytes(), img.pixel_bytes()),
						 self);
}

static bn::ndarray GetWorldPointsForFrame(const RecordedSequence &rs, size_t frameIndex)
{
	const chira::DepthImage &depth = rs.GetDepth(frameIndex);
	const poseinfer::camera_intrinsics &camera = rs.GetDepthIntrinsics();
	typedef decltype(camera.image_to_world(0, 0, static_cast<chira::DepthImage::value_type>(0))) _CoordTy;
	
	bn::dtype dtype = bn::dtype::get_builtin<_CoordTy::value_type>();
	bn::ndarray points = bn::empty(bp::make_tuple(depth.height(), depth.width(), 3u), dtype);

	// Fill array with world coordinates
	char *data = points.get_data();
	Py_intptr_t const * strides = points.get_strides();
	for (unsigned int y = 0; y < depth.height(); ++y)
	{
		for (unsigned int x = 0; x < depth.width(); ++x)
		{
			const auto &v = camera.image_to_world(x, y, depth(x, y));
			for (int k = 0; k < 3; ++k)
			{
				_CoordTy::value_type *ptr = reinterpret_cast<_CoordTy::value_type *>(data + y * strides[0] + x * strides[1] + k * strides[2]);
				*ptr = v[k];
			}
		}
	}

	return points;
}

static bn::ndarray GetWorldNormalsForFrame(const RecordedSequence &rs, size_t frameIndex)
{
	const chira::DepthImage &depth = rs.GetDepth(frameIndex);
	const pi::camera_intrinsics &camera = rs.GetDepthIntrinsics();

	bn::dtype dtype = bn::dtype::get_builtin<fs::scalar>();
	bn::ndarray normals = bn::empty(bp::make_tuple(depth.height(), depth.width(), 3u), dtype);

	// Get position image
	ts::image<fs::vec3> positions(depth.width(), depth.height());
	for (unsigned int y = 0; y < depth.height(); ++y)
	{
		for (unsigned int x = 0; x < depth.width(); ++x)
		{
			const auto &position = camera.image_to_world(x, y, depth(x, y));
			for (int k = 0; k < 3; ++k)
			{
				positions(x, y)[k] = position[k];
			}
		}
	}

	// Fill NumPy array with estimated normals
	char *data = normals.get_data();
	Py_intptr_t const * strides = normals.get_strides();
	for (unsigned int y = 0; y < depth.height(); ++y)
	{
		for (unsigned int x = 0; x < depth.width(); ++x)
		{
			// Get estimated normal
			fs::vec3 result;
			fs::estimate_normal_from_point_image(positions, x, y, result);
			for (int k = 0; k < 3; ++k)
			{
				fs::scalar *ptr = reinterpret_cast<fs::scalar *>(data + y * strides[0] + x * strides[1] + k * strides[2]);
				*ptr = result[k];
			}
		}
	}

	return normals;
}

BOOST_PYTHON_MODULE(_recordings)
{
	bn::initialize();

	bp::def("initialize_repo", &ChiraTest::InitializeRepo);

	bp::class_<RecordedSequence>("RecordedSequence", bp::init<std::wstring, bool>())
		.add_property("frame_count", &RecordedSequence::GetFrameCount)
		.add_property("sequence_root", &RecordedSequence::GetSequenceRoot)
		.def("get_time_stamp", &RecordedSequence::GetTimeStamp)
		.def("get_ms_from_seqstart", &RecordedSequence::GetMilliSecondsFromSequenceStart)
		.def("get_depth", &RecordedSequence::GetDepth)
		.def("get_depth_file_name", &RecordedSequence::GetDepthFileName)
		.def("get_world_points", &GetWorldPointsForFrame)
		.def("get_world_normals", &GetWorldNormalsForFrame)
		;

	bp::class_<chira::DepthImage>("DepthImage")
		.def("array", &image_object_to_ndarray<chira::DepthImage>);
}
