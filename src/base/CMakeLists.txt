mist_create_library(
  NAME
    base
  SRCS
    hello_world.cc
  LINK_DEPS
    fmt::fmt
  ENABLE_INSTALL
)

mist_generate_enum_for_library(
  NAME
    base
  SRCS
    ${CMAKE_SOURCE_DIR}/include/mist/base/grade.enum
)
