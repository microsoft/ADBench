#pragma once

#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"

using ::testing::TestWithParam;

class ModuleTest : public TestWithParam<std::tuple<const char*, double>> {
public:
    ~ModuleTest() override;
    void SetUp() override;
    void TearDown() override;
protected:
    double epsilon = 1e-8;
    ModuleLoader* moduleLoader;
};