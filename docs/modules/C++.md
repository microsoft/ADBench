# C++ Modules

## Adding new modules
1. Create a CMakeLists.txt file in the /src/cpp/modules/your_module directory to read as follows:
	```
	project("ADBench_YourModule" CXX)

	add_library("YourModule" MODULE)
	```
2. Open /src/cpp/modules/CMakeLists.txt and add the next string: 
	```
	add_subdirectory ("YourModule")
	```
3. For each objective create a class implementing ITest<TInput,TOuput> interface where T is an objective type (GMM, BA etc.). *TInput* and *TOutput* are input and output types specific for an objective. Their definitions are stored in the "../../shared/TData.h" file relatively to the directory of your module.
4. For each class add a class factory function just below class implementation as follows:
	```
	extern "C" DLL_PUBLIC ITest<TInput, TOutput>* get_T_test()
	{
	    return new YourClass();
	}
	```
	T is still an objective type here.
5. Specify target sources in the project CMakeLists.txt file.
6. Compile, run via C++ runner and enjoy!

Please, don't forget to add unit tests.