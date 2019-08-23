

# C++ Modules

## Adding new modules
1. Create a CMakeLists.txt file in the /src/cpp/modules/yourModule directory with the following content where "YourModule" is the name of your module:
	```
	project("ADBench_YourModule" CXX)

	add_library("YourModule" MODULE)
	```
	
	Note that [run-all.ps1 script](../Architecture.md#global-runner) expects directory name to be equal to module binary name but with a lowercase first letter.
2. Open /src/cpp/modules/CMakeLists.txt and add the next string: 
	```
	add_subdirectory ("YourModule")
	```
3. <span id="itest-implementation"> For each objective create a class implementing ITest<TInput,TOuput> interface where T is an objective type (GMM, BA etc.). *TInput* and *TOutput* are input and output types specific for the objective. They are defined in the file "../../shared/TData.h" (the path is relative to the directory of your module).
	 - virtual void prepare(TInput&& input) - should load input struct into module memory
	 - virtual  void  calculate_objective(int times) - should cyclically compute objective for *times* times
	 - virtual  void  calculate_jacobian(int times)  - should cyclically compute derivatives of an objective function for *times* times
	 - virtual TOutput output() - should return results of calculation via struct of TOutput  type
	</span>

4. For each class add an exported factory function just below class implementation as follows:
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
