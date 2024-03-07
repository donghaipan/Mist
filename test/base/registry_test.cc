#include <gtest/gtest.h>

// only include header file
#include "mist/base/registry.h"
#include "registry_dummy_base.h"

namespace mist::base {
struct RegistryTest : public ::testing::Test {};

TEST_F(RegistryTest, is_class_registered_test) {
  auto is_registered =
      isClassRegistered<std::string, registry_test::Base>("Foo");
  EXPECT_TRUE(is_registered);

  // NOTE: this is not registred!
  is_registered = isClassRegistered<std::string, registry_test::Base>("Foo", 1);
  EXPECT_TRUE(!is_registered);

  is_registered = isClassRegistered<std::string, registry_test::Base>("Bar", 1);
  EXPECT_TRUE(is_registered);

  is_registered =
      isClassRegistered<std::string, registry_test::Base>("Bar", 1, 2);
  EXPECT_TRUE(is_registered);
}

TEST_F(RegistryTest, registry_creator_test) {
  auto foo_ptr = createUniquePtr<std::string, registry_test::Base>("Foo");
  EXPECT_EQ(foo_ptr->getValue(), 0);

  auto bar_ptr_0 = createUniquePtr<std::string, registry_test::Base>("Bar", 1);
  EXPECT_EQ(bar_ptr_0->getValue(), 1);

  auto bar_ptr_1 =
      createUniquePtr<std::string, registry_test::Base>("Bar", 1, 2);
  EXPECT_EQ(bar_ptr_1->getValue(), 3);
}

TEST_F(RegistryTest, registry_creator_throw_test) {
  auto is_registered =
      isClassRegistered<std::string, registry_test::Base>("Foo", 1);
  EXPECT_TRUE(!is_registered);

  // auto validator = [](const std::exception &ex) {
  //   return std::string(ex.what()).find(
  //              "Cannot find registered factory method") != std::string::npos;
  // };

  auto runner = []() {
    createUniquePtr<std::string, registry_test::Base>("Foo", 1);
  };

  EXPECT_THROW(runner(), base::AssertionError);
}

} // namespace mist::base
