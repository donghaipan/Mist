include(MistHelpers)

set(PROTO_HDRS)
set(PROTO_SRCS)
set(PROTOC_PRG ${Protobuf_PROTOC_EXECUTABLE})

set(CC_PROTO_INPUT_PATH "${CMAKE_SOURCE_DIR}/include")
set(CC_PROTO_OUTPUT_PATH "${CMAKE_BINARY_DIR}/include")

# create output directory, otherwise it would fail for make
if(NOT EXISTS ${CC_PROTO_OUTPUT_PATH})
  file(MAKE_DIRECTORY ${CC_PROTO_OUTPUT_PATH})
endif()

file(
  GLOB_RECURSE proto_files
  RELATIVE ${CC_PROTO_INPUT_PATH}
  "include/mist/proto/*.proto")

# Get Protobuf include dir
get_target_property(protobuf_dirs protobuf::libprotobuf
                    INTERFACE_INCLUDE_DIRECTORIES)
foreach(dir IN LISTS protobuf_dirs)
  if(NOT "${dir}" MATCHES "INSTALL_INTERFACE|-NOTFOUND")
    message(STATUS "Adding proto path: ${dir}")
    list(APPEND PROTO_DIRS "--proto_path=${dir}")
  endif()
endforeach()

foreach(PROTO_FILE IN LISTS proto_files)
  get_filename_component(PROTO_DIR ${PROTO_FILE} DIRECTORY)
  get_filename_component(PROTO_NAME ${PROTO_FILE} NAME_WE)
  set(PROTO_HDR ${CC_PROTO_OUTPUT_PATH}/${PROTO_DIR}/${PROTO_NAME}.pb.h)
  set(PROTO_SRC ${CC_PROTO_OUTPUT_PATH}/${PROTO_DIR}/${PROTO_NAME}.pb.cc)
  add_custom_command(
    OUTPUT ${PROTO_SRC} ${PROTO_HDR}
    COMMAND ${PROTOC_PRG} "--proto_path=${CC_PROTO_INPUT_PATH}" ${PROTO_DIRS}
            "--cpp_out=${CC_PROTO_OUTPUT_PATH}" ${PROTO_FILE}
    DEPENDS ${CC_PROTO_INPUT_PATH}/${PROTO_FILE} ${PROTOC_PRG}
    COMMENT "Generate C++ protocol buffer for ${PROTO_FILE}"
    VERBATIM)
  list(APPEND PROTO_HDRS ${PROTO_HDR})
  list(APPEND PROTO_SRCS ${PROTO_SRC})
endforeach()

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  set(MIST_PROTO_ADDL_COPTS "-Wno-missing-declarations")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(MIST_PROTO_ADDL_COPTS "-Wno-missing-prototypes" "-Wno-sign-conversion")
else()
  set(MIST_PROTO_ADDL_COPTS "")
endif()

mist_create_library(
  NAME
  proto
  SRCS
  ${PROTO_SRCS}
  ${PROTO_HDRS}
  LINK_DEPS
  protobuf::libprotobuf
  COMPILE_OPTS
  ${MIST_PROTO_ADDL_COPTS}
  INCLUDE_DIRS
  PUBLIC
  $<BUILD_INTERFACE:${CC_PROTO_OUTPUT_PATH}>
  ENABLE_INSTALL)

install(
  DIRECTORY ${CC_PROTO_OUTPUT_PATH}/mist
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  FILES_MATCHING
  PATTERN "*.pb.h")
