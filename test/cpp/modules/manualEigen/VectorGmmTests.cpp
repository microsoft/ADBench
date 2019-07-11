#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"
#include "../../../../src/cpp/shared/utils.h"
namespace {

using ::testing::TestWithParam;
using ::testing::Values;
//TEST(GmmTests, ManualEigenVector_Load) {
//    ModuleLoader moduleLoader("../../../../src/cpp/modules/manualEigen/ManualEigenVector.dll");
//    auto test = moduleLoader.get_gmm_test();
//    ASSERT_NE(test, nullptr);
//}
//
//TEST(GmmTests, ManualEigenVector_TestProcess)
//{
//    ModuleLoader moduleLoader("../../../../src/cpp/modules/manualEigen/ManualEigenVector.dll");
//    auto module = moduleLoader.get_gmm_test();
//    ASSERT_NE(module, nullptr);
//    GMMInput input;
//
//    // Read instance
//    read_gmm_instance("gmmtest.txt", &input.d, &input.k, &input.n,
//        input.alphas, input.means, input.icf, input.x, input.wishart, false);
//    module->prepare(std::move(input));
//    module->calculateObjective(1);
//    module->calculateJacobian(1);
//    auto output = module->output();
//    EXPECT_NEAR(8.0738, output.objective, 0.00001);
//    EXPECT_EQ(18, output.gradient.size());
//    EXPECT_NEAR(0.108663, output.gradient[0], 0.00001);
//    EXPECT_NEAR(-0.74127, output.gradient[1], 0.00001);
//    EXPECT_NEAR(0.632607, output.gradient[2], 0.00001);
//    EXPECT_NEAR(1.116926, output.gradient[3], 0.00001);
//    EXPECT_NEAR(0.163333, output.gradient[4], 0.00001);
//    EXPECT_NEAR(-0.022, output.gradient[5], 0.00001);
//    EXPECT_NEAR(0.227778, output.gradient[6], 0.00001);
//    EXPECT_NEAR(1.20963, output.gradient[7], 0.00001);
//    EXPECT_NEAR(-0.06064, output.gradient[8], 0.00001);
//    EXPECT_NEAR(2.5853, output.gradient[9], 0.00001);
//    EXPECT_NEAR(0.11263, output.gradient[10], 0.00001);
//    EXPECT_NEAR(0.38574, output.gradient[11], 0.00001);
//    EXPECT_NEAR(0.07352, output.gradient[12], 0.00001);
//    EXPECT_NEAR(5.41836, output.gradient[13], 0.00001);
//    EXPECT_NEAR(-0.3215, output.gradient[14], 0.00001);
//    EXPECT_NEAR(1.71892, output.gradient[15], 0.00001);
//    EXPECT_NEAR(0.86009, output.gradient[16], 0.00001);
//    EXPECT_NEAR(-0.99464, output.gradient[17], 0.00001);
//}

// The interface and its implementations are in this header.
//#include "prime_tables.h"

    //using ::testing::TestWithParam;
    //using ::testing::Values;

    //// As a general rule, to prevent a test from affecting the tests that come
    //// after it, you should create and destroy the tested objects for each test
    //// instead of reusing them.  In this sample we will define a simple factory
    //// function for PrimeTable objects.  We will instantiate objects in test's
    //// SetUp() method and delete them in TearDown() method.
    //typedef GmmTest* CreateGmmTestFunc();

    //GmmTest* CreateOnTheFlyGmmTest() {
    //    return new OnTheFlyGmmTest();
    //}

    //template <size_t max_precalculated>
    //GmmTest* CreatePreCalculatedGmmTest() {
    //    return new PreCalculatedGmmTest(max_precalculated);
    //}

    //// Inside the test body, fixture constructor, SetUp(), and TearDown() you
    //// can refer to the test parameter by GetParam().  In this case, the test
    //// parameter is a factory function which we call in fixture's SetUp() to
    //// create and store an instance of PrimeTable.
    //class GmmTests : public TestWithParam<CreateGmmTestFunc*> {
    //public:
    //    ~GmmTests() override { delete test; }
    //    void SetUp() override { test = (*GetParam())(); }
    //    void TearDown() override {
    //        delete test;
    //        test = nullptr;
    //    }

    //protected:
    //    GmmTest* test;
    //};

    //TEST_P(GmmTests, ReturnsFalseForNonPrimes) {
    //    EXPECT_FALSE(test->IsPrime(-5));
    //    EXPECT_FALSE(test->IsPrime(0));
    //    EXPECT_FALSE(test->IsPrime(1));
    //    EXPECT_FALSE(test->IsPrime(4));
    //    EXPECT_FALSE(test->IsPrime(6));
    //    EXPECT_FALSE(test->IsPrime(100));
    //}

    //TEST_P(GmmTests, ReturnsTrueForPrimes) {
    //    EXPECT_TRUE(test->IsPrime(2));
    //    EXPECT_TRUE(test->IsPrime(3));
    //    EXPECT_TRUE(test->IsPrime(5));
    //    EXPECT_TRUE(test->IsPrime(7));
    //    EXPECT_TRUE(test->IsPrime(11));
    //    EXPECT_TRUE(test->IsPrime(131));
    //}

//struct test_module
//{
//    char* module_path;
//    friend std::ostream& operator<<(std::ostream& os, const test_module& obj)
//    {
//        return os
//            << "module_path: " << obj.module_path;
//    }
//};
//
//struct ModuleTest : testing::Test, testing::WithParamInterface<test_module>
//{
//    char* str = GetParam().module_path;
//    ModuleLoader moduleLoader = ModuleLoader(str);
//    ModuleTest()
//    {
//        auto module = moduleLoader.get_gmm_test();
//    }
//    virtual ~ModuleTest()
//    {
//        delete moduleLoader;
//    }
//};

/*TEST_F(ModuleTest, load)
{
    module->deposit(100);
    EXPECT_EQ(100, account->balance);
}*/


//struct GmmModuleTest : ModuleTest, testing::WithParamInterface<test_module>
//{
//    GmmModuleTest()
//    {
//        module->balance = GetParam().initial_balance;
//    }
//};

//struct ModuleTest : testing::WithParamInterface<test_module>
//{
//    ModuleTest()
//    {
//        //module->balance = GetParam().initial_balance;
//    }
//};

typedef ModuleLoader* CreateModuleLoaderFunc();

ModuleLoader* CreateOnTheFlyModuleLoader(const char* path) {
    return new ModuleLoader(path);
}

class ModuleTest : public TestWithParam<CreateModuleLoaderFunc*> {
public:
    ~ModuleTest() override { delete moduleLoader; }
    void SetUp() override
    {
       /* auto str = GetParam();
        ModuleLoader moduleLoader(str);*/
        moduleLoader = (*GetParam())();
    }
    void TearDown() override {
        delete moduleLoader;
        moduleLoader = nullptr;
    }
protected:
    ModuleLoader* moduleLoader;
};

//class ModuleTest : public TestWithParam<const char*> {
//protected:
//    ~ModuleTest() override { /*delete moduleLoader;*/ }
//    void SetUp() override
//    {
//        auto str = GetParam();
//        ModuleLoader moduleLoader(str);
//    }
//    void TearDown() override {
//        /*delete moduleLoader;
//        moduleLoader = nullptr;*/
//    }
//    ModuleLoader* moduleLoader;
//};

TEST_P(ModuleTest, Load)
{
    auto module = moduleLoader->get_gmm_test();
    ASSERT_NE(module, nullptr);
    GMMInput input;

    // Read instance
    read_gmm_instance("gmmtest.txt", &input.d, &input.k, &input.n,
        input.alphas, input.means, input.icf, input.x, input.wishart, false);
    module->prepare(std::move(input));
    module->calculateObjective(1);
    module->calculateJacobian(1);
    auto output = module->output();
    EXPECT_NEAR(8.0738, output.objective, 0.00001);
    EXPECT_EQ(18, output.gradient.size());
    EXPECT_NEAR(0.108663, output.gradient[0], 0.00001);
    EXPECT_NEAR(-0.74127, output.gradient[1], 0.00001);
    EXPECT_NEAR(0.632607, output.gradient[2], 0.00001);
    EXPECT_NEAR(1.116926, output.gradient[3], 0.00001);
    EXPECT_NEAR(0.163333, output.gradient[4], 0.00001);
    EXPECT_NEAR(-0.022, output.gradient[5], 0.00001);
    EXPECT_NEAR(0.227778, output.gradient[6], 0.00001);
    EXPECT_NEAR(1.20963, output.gradient[7], 0.00001);
    EXPECT_NEAR(-0.06064, output.gradient[8], 0.00001);
    EXPECT_NEAR(2.5853, output.gradient[9], 0.00001);
    EXPECT_NEAR(0.11263, output.gradient[10], 0.00001);
    EXPECT_NEAR(0.38574, output.gradient[11], 0.00001);
    EXPECT_NEAR(0.07352, output.gradient[12], 0.00001);
    EXPECT_NEAR(5.41836, output.gradient[13], 0.00001);
    EXPECT_NEAR(-0.3215, output.gradient[14], 0.00001);
    EXPECT_NEAR(1.71892, output.gradient[15], 0.00001);
    EXPECT_NEAR(0.86009, output.gradient[16], 0.00001);
    EXPECT_NEAR(-0.99464, output.gradient[17], 0.00001);
}

// In order to run value-parameterized tests, you need to instantiate them,
// or bind them to a list of values which will be used as test parameters.
// You can instantiate them in a different translation module, or even
// instantiate them several times.
//
// Here, we instantiate our tests with a list of two PrimeTable object
// factory functions:

//INSTANTIATE_TEST_SUITE_P
INSTANTIATE_TEST_CASE_P(GmmModuleTest, ModuleTest,
    ::testing::Values(
        &CreateOnTheFlyModuleLoader("../../../../src/cpp/modules/manualEigen/ManualEigenVector.dll"),
        &CreateOnTheFlyModuleLoader("../../../../src/cpp/modules/manualEigen/ManualEigen.dll")
));

}  // namespace