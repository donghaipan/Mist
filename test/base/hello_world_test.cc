#include "gtest/gtest.h"

#include "mist/base/hello_world.h"

using namespace ::mist::base;

TEST(HelloWorldTest, TestReturn) {
  EXPECT_EQ(mist::base::HelloWorld(), "Hello World!");
}
