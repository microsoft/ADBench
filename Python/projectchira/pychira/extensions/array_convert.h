#include <boost/numpy.hpp>

namespace bn = boost::numpy;
namespace bp = boost::python;

// Convert by-value from a C++ array type to a Python numpy array
template <typename _ArrTy, typename _ScalarTy, int _N>
struct array_to_numpy
{
	static PyObject *convert(const _ArrTy &a)
	{
		// Create a numpy array of the right size and type
		std::unique_ptr<bn::ndarray> arr = std::make_unique<bn::ndarray>(bn::empty(bp::make_tuple(_N), bn::dtype::get_builtin<_ScalarTy>()));
		// Get a pointer to the numpy data
		_ScalarTy *data = reinterpret_cast<_ScalarTy *>(arr->get_data());
		// Fill the numpy array from the C++ array
		for (int i = 0; i < _N; ++i, ++data) *data = a[i];
		return arr.release()->ptr();
	}
};

// Convert by-value from numpy array to a C++ array type.
// (Based on the Boost.NumPy "gaussian" example)
template <typename _ArrTy, typename _ScalarTy, int _N>
struct array_from_numpy
{
	// Register the converter.
	array_from_numpy() {
		bp::converter::registry::push_back(
			&convertible,
			&construct,
			bp::type_id<_ArrTy>()
			);
	}

	// Test to see if we can convert this to the desired type; if not return zero.
	// If we can convert, returned pointer can be used by construct().
	static void *convertible(PyObject * p) {
		try
		{
			bp::object obj(bp::handle<>(bp::borrowed(p)));
			std::unique_ptr<bn::ndarray> arr = std::make_unique<bn::ndarray>(
				bn::from_object(obj, bn::dtype::get_builtin<_ScalarTy>(), 1, 1, bn::ndarray::V_CONTIGUOUS)
				);
			if (arr->shape(0) != _N) return nullptr;
			return arr.release();
		}
		catch (bp::error_already_set &)
		{
			bp::handle_exception();
			return nullptr;
		}
	}

	// Finish the conversion by initializing the C++ object into memory prepared by Boost.Python.
	static void construct(PyObject * obj, bp::converter::rvalue_from_python_stage1_data *data) {
		// Extract the array we passed out of the convertible() member function.
		std::unique_ptr<bn::ndarray> arr(reinterpret_cast<bn::ndarray *>(data->convertible));
		// Find the memory block Boost.Python has prepared for the result.
		typedef bp::converter::rvalue_from_python_storage<_ArrTy> storage_t;
		storage_t *storage = reinterpret_cast<storage_t *>(data);
		// Use placement new to initialize the result.
		_ArrTy *array_ptr = new (storage->storage.bytes) _ArrTy();
		// Fill the result with the values from the NumPy array.
		for (int i = 0; i < _N; ++i) (*array_ptr)[i] = bp::extract<_ScalarTy>((*arr)[i]);
		// Finish up.
		data->convertible = storage->storage.bytes;
	}
};

// Register to and from converters for an array type
template <typename _ArrTy, typename _ScalarTy, int _N>
void python_array_byvalue_converters()
{
	bp::to_python_converter<_ArrTy, array_to_numpy<_ArrTy, _ScalarTy, _N>>();
	array_from_numpy<_ArrTy, _ScalarTy, _N>();
};
