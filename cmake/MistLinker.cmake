# TODO: fix linking error on GNU with lld
if(USE_LLD)
  set(LLD_LINKER_FLAGS "-fuse-ld=lld -Wl,--gdb-index")
  list(APPEND CMAKE_EXE_LINKER_FLAGS ${LLD_LINKER_FLAGS})
  list(APPEND CMAKE_SHARED_LINKER_FLAGS ${LLD_LINKER_FLAGS})
  list(APPEND CMAKE_MODULE_LINKER_FLAGS ${LLD_LINKER_FLAGS})
  message(STATUS "Use llvm lld linker, flags: ${LLD_LINKER_FLAGS}")
endif()

if(USE_TIME_TRACE)
  if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    list(APPEND CMAKE_CXX_FLAGS "-ftime-trace")
    message(STATUS "Enable Clang time-trace")
  endif()
  if(USE_LLD)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--time-trace")
    set(CMAKE_SHARED_LINKER_FLAGS
        "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--time-trace")
    set(CMAKE_MODULE_LINKER_FLAGS
        "${CMAKE_MODULE_LINKER_FLAGS} -Wl,--time-trace")
  endif()
endif()

# link time optimization
if(USE_IPO)
  include(CheckIPOSupported)
  check_ipo_supported(RESULT IPO_SUPPORTED OUTPUT IPO_OUTPUT)
  if(IPO_SUPPORTED)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
    message(STATUS "Enable interprocedural optimization")
  else()
    message(FATAL_ERROR "IPO is not supported: ${IPO_OUTPUT}")
  endif()
endif()
