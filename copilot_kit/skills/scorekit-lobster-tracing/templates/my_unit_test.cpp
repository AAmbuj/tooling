/********************************************************************************
 * Copyright (c) <YEAR> <COPYRIGHT HOLDER>
 *
 * SPDX-License-Identifier: Apache-2.0
 ********************************************************************************/
// Destination: src/my_unit_test.cpp
#include <gtest/gtest.h>

#include "src/my_unit.h"

// Test UID in the lock file: //<bazel_package>/<Suite>:<Test>, e.g. //MyUnitTest:DoWorkReturnsResult
TEST(MyUnitTest, DoWorkReturnsResult) {
  ::testing::Test::RecordProperty("lobster-tracing", "MyModule.COMP_001");
  ::testing::Test::RecordProperty("given", "a default-constructed MyUnit");
  MyUnit unit{};
  ::testing::Test::RecordProperty("when", "DoWork is called once");
  const int result = unit.DoWork();
  ::testing::Test::RecordProperty("then", "it returns the number of calls so far (1)");
  EXPECT_EQ(result, 1);
}
