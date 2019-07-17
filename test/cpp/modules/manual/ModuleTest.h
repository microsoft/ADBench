#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"

using ::testing::TestWithParam;

class ModuleTest : public TestWithParam<const char*> {
public:
    ~ModuleTest() override;
    void SetUp() override;
    void TearDown() override;
protected:
    ModuleLoader* moduleLoader;
};