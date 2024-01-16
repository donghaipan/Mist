include(CMakeParseArguments)
include(GNUInstallDirs)
# compile flags
include(MistCopts)

function(mist_library_registry name)
  set(target_name "mist_${name}")
  set(REGISTRY_PATTERN "MistGlobalRegistry_")
  get_target_property(target_type ${target_name} TYPE)
  if(NOT target_type MATCHES "LIBRARY")
    message(FATAL_ERROR "Registration can only applied to libraries")
  endif()

  set(registry_target_name ${PROJECT_NAME}::${target_name})

  set(registry_file
      $<TARGET_FILE:$<IF:$<TARGET_EXISTS:${registry_target_name}>,${registry_target_name},${target_name}>>
  )
  set(awk_arg "{ print \"-u \" $1 }")
  add_custom_command(
    TARGET ${target_name}
    POST_BUILD
    COMMAND
      nm --format=p $<TARGET_FILE:${target_name}> | grep ${REGISTRY_PATTERN} |
      awk ${awk_arg} > $<TARGET_FILE:${target_name}>.registry_vars
    VERBATIM)

  target_link_options(${target_name} INTERFACE
                      "-Wl,@${registry_file}.registry_vars")

  install(FILES $<TARGET_FILE:${target_name}>.registry_vars
          DESTINATION ${CMAKE_INSTALL_LIBDIR})
endfunction()

function(mist_create_library)
  set(options "ENABLE_INSTALL")
  set(one_value_args "NAME;OUTPUT_DIRECTORY")
  set(multi_value_args
      "SRCS;LINK_DEPS;PRIVATE_LINK_DEPS;INCLUDE_DIRS;LINK_OPTS;COMPILE_DEFS;COMPILE_OPTS"
  )
  cmake_parse_arguments(cc_lib "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  set(LIB_SRC_FILES "${cc_lib_SRCS}")

  # Determine if it is interface library
  list(FILTER LIB_SRC_FILES EXCLUDE REGEX ".*\\.(h|ipp)")
  if(LIB_SRC_FILES STREQUAL "")
    set(LIB_IS_INTERFACE 1)
  else()
    set(LIB_IS_INTERFACE 0)
  endif()

  set(LIB_NAME "mist_${cc_lib_NAME}")
  if(NOT LIB_IS_INTERFACE)
    add_library(${LIB_NAME} "")
    target_sources(${LIB_NAME} PRIVATE ${cc_lib_SRCS})
    target_link_libraries(
      ${LIB_NAME}
      PUBLIC ${cc_lib_LINK_DEPS}
      PRIVATE ${cc_lib_PRIVATE_LINK_DEPS})
    target_include_directories(
      ${LIB_NAME} ${cc_lib_INCLUDE_DIRS}
      PUBLIC $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
      PUBLIC $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
    target_link_options(${LIB_NAME} PRIVATE ${cc_lib_LINK_OPTS})
    target_compile_options(${LIB_NAME} PRIVATE ${MIST_DEFAULT_COPTS})
    target_compile_options(${LIB_NAME} PRIVATE ${cc_lib_COMPILE_OPTS})
    target_compile_definitions(${LIB_NAME} PUBLIC ${cc_lib_COMPILE_DEFS})

    if(cc_lib_OUTPUT_DIRECTORY)
      set_target_properties(
        ${LIB_NAME}
        PROPERTIES ARCHIVE_OUTPUT_DIRECTORY ${cc_lib_OUTPUT_DIRECTORY}
                   LIBRARY_OUTPUT_DIRECTORY ${cc_lib_OUTPUT_DIRECTORY})
    else()
      set_target_properties(
        ${LIB_NAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
                               LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
    endif()

  else()
    add_library(${LIB_NAME} INTERFACE)
    target_include_directories(
      ${LIB_NAME} ${cc_lib_INCLUDE_DIRS}
      INTERFACE $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
      INTERFACE $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
    target_link_libraries(${LIB_NAME} INTERFACE ${cc_lib_LINK_DEPS})
    target_compile_definitions(${LIB_NAME} INTERFACE ${cc_lib_COMPILE_DEFS})
  endif()

  if(cc_lib_ENABLE_INSTALL)
    install(
      TARGETS ${LIB_NAME}
      EXPORT ${PROJECT_NAME}Targets
      LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
      ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
  endif()

  # create an alias
  add_library(${PROJECT_NAME}::${cc_lib_NAME} ALIAS ${LIB_NAME})
endfunction()

function(mist_create_executable)
  set(options "ENABLE_INSTALL")
  set(one_value_args "NAME;OUTPUT_DIRECTORY")
  set(multi_value_args
      "SRCS;LINK_DEPS;INCLUDE_DIRS;LINK_OPTS;COMPILE_DEFS;COMPILE_OPTS;COPY_FILES"
  )

  cmake_parse_arguments(cc_exe "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})
  set(EXECUTABLE_NAME ${cc_exe_NAME})
  add_executable(${EXECUTABLE_NAME} ${cc_exe_SRCS})
  target_link_libraries(${EXECUTABLE_NAME} PRIVATE ${cc_exe_LINK_DEPS})
  target_compile_definitions(${EXECUTABLE_NAME} PRIVATE ${cc_exe_COMPILE_DEFS})
  target_compile_options(${EXECUTABLE_NAME} PRIVATE ${cc_exe_COMPILE_OPTS})
  target_include_directories(${EXECUTABLE_NAME} PRIVATE ${cc_exe_INCLUDE_DIRS})
  target_link_options(${EXECUTABLE_NAME} PRIVATE ${cc_exe_LINK_OPTS})

  if(cc_exe_OUTPUT_DIRECTORY)
    set(EXECUTABLE_OUTPUT_DIRECTORY ${cc_exe_OUTPUT_DIRECTORY})
  else()
    set(EXECUTABLE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
  endif()

  set_target_properties(
    ${EXECUTABLE_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY
                                  ${EXECUTABLE_OUTPUT_DIRECTORY})

  # NOTE: Since we don't install our test binary, we won't install the copied
  # files to our package.
  foreach(file_name ${cc_exe_COPY_FILES})
    file(COPY ${file_name} DESTINATION ${EXECUTABLE_OUTPUT_DIRECTORY})
  endforeach()

  if(cc_exe_ENABLE_INSTALL)
    install(TARGETS ${EXECUTABLE_NAME}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
  endif()
endfunction()

# we do not install unit tests
function(mist_create_unit_test)
  set(options "")
  set(one_value_args "NAME")
  set(multi_value_args
      "SRCS;LINK_DEPS;INCLUDE_DIRS;LINK_OPTS;COMPILE_DEFS;COMPILE_OPTS;SUITES;COPY_FILES"
  )
  cmake_parse_arguments(cc_test "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})
  foreach(
    property
    NAME
    SRCS
    LINK_DEPS
    LINK_OPTS
    COMPILE_DEFS
    INCLUDE_DIRS
    COPY_FILES)
    if(cc_test_${property})
      list(APPEND exe_args ${property} ${cc_test_${property}})
    endif()
  endforeach()

  set(CC_TEST_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin/test)

  list(APPEND exe_args "OUTPUT_DIRECTORY" ${CC_TEST_OUTPUT_DIRECTORY})
  list(APPEND exe_args "COMPILE_OPTS" ${MIST_TEST_COPTS}
       ${cc_test_COMPILE_OPTS})
  mist_create_executable(${exe_args})

  # add test
  if(cc_test_SUITES)
    foreach(suite_name ${cc_test_SUITES})
      add_test(
        NAME ${cc_test_NAME}-${suite_name}
        COMMAND ${cc_test_NAME} --run_test=${suite_name}
        WORKING_DIRECTORY ${CC_TEST_OUTPUT_DIRECTORY})
    endforeach()
  else()
    add_test(
      NAME ${cc_test_NAME}
      COMMAND ${cc_test_NAME}
      WORKING_DIRECTORY ${CC_TEST_OUTPUT_DIRECTORY})
  endif()
endfunction()

function(mist_create_application)
  set(options "ENABLE_INSTALL")
  set(one_value_args "NAME")
  set(multi_value_args
      "SRCS;LINK_DEPS;INCLUDE_DIRS;LINK_OPTS;COMPILE_DEFS;COMPILE_OPTS;COPY_FILES"
  )
  cmake_parse_arguments(cc_app "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})
  foreach(
    property
    ENABLE_INSTALL
    NAME
    SRCS
    LINK_DEPS
    LINK_OPTS
    COMPILE_DEFS
    INCLUDE_DIRS
    COPY_FILES)
    if(cc_app_${property})
      list(APPEND exe_args ${property} ${cc_app_${property}})
    endif()
  endforeach()

  list(APPEND exe_args "OUTPUT_DIRECTORY" ${CMAKE_BINARY_DIR}/bin)
  list(APPEND exe_args "COMPILE_OPTS" ${MIST_DEFAULT_COPTS}
       ${cc_app_COMPILE_OPTS})
  mist_create_executable(${exe_args})
endfunction()

function(mist_create_benchmark)
  set(options "")
  set(one_value_args "NAME")
  set(multi_value_args
      "SRCS;LINK_DEPS;INCLUDE_DIRS;LINK_OPTS;COMPILE_DEFS;COMPILE_OPTS;COPY_FILES"
  )
  cmake_parse_arguments(cc_benchmark "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})
  foreach(
    property
    NAME
    SRCS
    LINK_DEPS
    LINK_OPTS
    COMPILE_DEFS
    INCLUDE_DIRS
    COPY_FILES)
    if(cc_benchmark_${property})
      list(APPEND exe_args ${property} ${cc_benchmark_${property}})
    endif()
  endforeach()

  set(CC_BENCHMARK_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin/benchmark)

  list(APPEND exe_args "OUTPUT_DIRECTORY" ${CC_BENCHMARK_OUTPUT_DIRECTORY})
  list(APPEND exe_args "COMPILE_OPTS" ${MIST_BENCHMARK_COPTS}
       ${cc_benchmark_COMPILE_OPTS})
  mist_create_executable(${exe_args})

endfunction()
