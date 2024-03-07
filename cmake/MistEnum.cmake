find_package (Python3 COMPONENTS Interpreter)

# users should not call this function. This function serves as a base function,
# and is only used inside test/mist/base/CMakeLists.txt for testing purpose
function(mist_generate_enum)
  set(options "")
  set(one_value_args "NAME;REL_PATH;OUTPUT_PATH")
  set(multi_value_args "SRCS")
  cmake_parse_arguments(cc_enum "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  set(ENUM_FILES)
  set(ENUM_HDRS)
  foreach(FILE_NAME ${cc_enum_SRCS})
    file(RELATIVE_PATH TEMP ${cc_enum_REL_PATH} ${FILE_NAME})
    list(APPEND ENUM_FILES ${TEMP})
  endforeach()

  set(ENUM_GENERATOR ${CMAKE_SOURCE_DIR}/tools/codegen/enum_generator.py)

  # create output directory, otherwise it would fail for make
  if(NOT EXISTS ${cc_enum_OUTPUT_PATH})
    file(MAKE_DIRECTORY ${cc_enum_OUTPUT_PATH})
  endif()

  foreach(ENUM_FILE IN LISTS ENUM_FILES)
    get_filename_component(FILE_DIR ${ENUM_FILE} DIRECTORY)
    get_filename_component(FILE_NAME ${ENUM_FILE} NAME_WE)
    set(ENUM_HDR ${cc_enum_OUTPUT_PATH}/${FILE_DIR}/${FILE_NAME}.h)

    add_custom_command(
      OUTPUT ${ENUM_HDR}
      COMMAND ${Python3_EXECUTABLE} ${ENUM_GENERATOR}
              "--input=${cc_enum_REL_PATH}/${ENUM_FILE}" "--output=${ENUM_HDR}"
      DEPENDS ${ENUM_GENERATOR} ${cc_enum_REL_PATH}/${ENUM_FILE}
      COMMENT "Generate enum header for ${ENUM_FILE}"
      VERBATIM)
    list(APPEND ENUM_HDRS ${ENUM_HDR})
  endforeach()

  set(lib_name "${cc_enum_NAME}")
  set(source_target "${cc_enum_NAME}_enum_codegen")

  add_custom_target(${source_target} DEPENDS ${ENUM_HDRS})
  target_sources(${source_target} PRIVATE ${ENUM_HDRS})

  add_dependencies(${lib_name} ${source_target})
  get_target_property(lib_type ${lib_name} TYPE)

  if(${lib_type} STREQUAL "INTERFACE_LIBRARY")
    target_include_directories(
      ${lib_name} INTERFACE $<BUILD_INTERFACE:${cc_enum_OUTPUT_PATH}>)
  else()
    target_include_directories(${lib_name}
                               PUBLIC $<BUILD_INTERFACE:${cc_enum_OUTPUT_PATH}>)
  endif()
endfunction()

function(mist_generate_enum_for_library)
  set(options "")
  set(one_value_args "NAME")
  set(multi_value_args "SRCS")
  cmake_parse_arguments(cc_enum "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  set(lib_name "mist_${cc_enum_NAME}")
  set(rel_path ${CMAKE_SOURCE_DIR}/include)
  set(output_path ${CMAKE_BINARY_DIR}/enum_codegen)
  mist_generate_enum(
    NAME
    ${lib_name}
    SRCS
    ${cc_enum_SRCS}
    REL_PATH
    ${rel_path}
    OUTPUT_PATH
    ${output_path})
endfunction()

install(
  DIRECTORY ${CMAKE_BINARY_DIR}/enum_codegen/mist
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  FILES_MATCHING
  PATTERN "*.h")
