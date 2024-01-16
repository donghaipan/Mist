# default flags
list(
  APPEND
  MIST_GCC_FLAGS
  "-Wall"
  "-Wextra"
  "-Werror"
  "-Wcast-qual"
  "-Wconversion-null"
  "-Wformat-security"
  "-Wmissing-declarations"
  "-Woverlength-strings"
  "-Wpointer-arith"
  "-Wundef"
  "-Wunused-local-typedefs"
  "-Wunused-result"
  "-Wvarargs"
  "-Wvla"
  "-Wwrite-strings")

# additional test flags
list(APPEND MIST_GCC_TEST_FLAGS "")

list(
  APPEND
  MIST_LLVM_FLAGS
  "-Wall"
  "-Wextra"
  "-Werror"
  "-Wcast-qual"
  "-Wconversion"
  "-Wfloat-overflow-conversion"
  "-Wfloat-zero-conversion"
  "-Wfor-loop-analysis"
  "-Wformat-security"
  "-Wgnu-redeclared-enum"
  "-Winfinite-recursion"
  "-Winvalid-constexpr"
  "-Wliteral-conversion"
  "-Wmissing-declarations"
  "-Wmissing-prototypes"
  "-Woverlength-strings"
  "-Wpointer-arith"
  "-Wself-assign"
  "-Wshadow-all"
  "-Wstring-conversion"
  "-Wtautological-overlap-compare"
  "-Wundef"
  "-Wuninitialized"
  "-Wunreachable-code"
  "-Wunused-comparison"
  "-Wunused-local-typedefs"
  "-Wunused-result"
  "-Wvla")

# additional test flags
list(APPEND MIST_LLVM_TEST_FLAGS "")

# currently set the benchmark flags the same as test flags. can customize in the
# future
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  set(MIST_DEFAULT_COPTS "${MIST_GCC_FLAGS}")
  set(MIST_TEST_COPS "${MIST_GCC_FLAGS};${MIST_GCC_TEST_FLAGS}")
  set(MIST_BENCHMARK_COPTS "${MIST_TEST_COPS}")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(MIST_DEFAULT_COPTS "${MIST_LLVM_FLAGS}")
  set(MIST_TEST_COPS "${MIST_LLVM_FLAGS};${MIST_LLVM_TEST_FLAGS}")
  set(MIST_BENCHMARK_COPTS "${MIST_TEST_COPS}")
else()
  message(
    FATAL_ERROR
      "Unknown compiler: ${CMAKE_CXX_COMPILER}.  Building with no default flags"
  )
  set(MIST_DEFAULT_COPTS "")
  set(MIST_TEST_COPTS "")
  set(MIST_BENCHMARK_COPTS "")
endif()
