# create test dummy library
mist_create_library(
  NAME
    registry_dummy_base
  SRCS
    registry_dummy_base.cc
  LINK_DEPS
    Mist::base
)

# DO NOT REMOVE THIS LINE
mist_library_registry(registry_dummy_base)

mist_create_unit_test(
  NAME
    BaseTest
  SRCS
    hello_world_test.cc
    registry_test.cc
  LINK_DEPS
    Mist::base
    Mist::registry_dummy_base
    GTest::gtest_main
)
