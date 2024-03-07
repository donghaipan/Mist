#pragma once

#include "mist/base/macro.h"
#include <cassert>
#include <cstring>
#include <stdexcept>
#include <string>

// Sadly, assert doesn't support an error message. A general way to add error
// message is via &&:
//
// MIST_ASSERT( (1==2) && "something is wrong!")
//
#ifdef MIST_NO_DEBUG
#define MIST_ASSERT(x)
#else
#define MIST_ASSERT(x) assert(x); // don't remove the ";"
#endif

#define MIST_DEFINE_ERROR(ErrorType, BaseType)                                 \
  class ErrorType : public BaseType {                                          \
  public:                                                                      \
    ErrorType(const std::string &what_arg) : BaseType(what_arg) {}             \
    ErrorType(const char *what_arg) : BaseType(what_arg) {}                    \
  };

// only show filename stem instead of full path
#define MIST_FILENAME                                                          \
  (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)

// Macros to throw error
namespace mist::base {

MIST_DEFINE_ERROR(AssertionError, std::logic_error);
MIST_DEFINE_ERROR(SizeMisMatchError, std::logic_error);
MIST_DEFINE_ERROR(UnknownEnumError, std::logic_error);

template <class ErrorType>
inline void assertionImpl(const char *check, const char *message,
                          const char *filename, const int line_number,
                          const char *func_name) {
  // 128^2
  char buffer[16384];
  const char *print_fmt = "%s:%d: %s: %s failed, %s";
  const auto cnt = snprintf(nullptr, 0, print_fmt, filename, line_number,
                            func_name, check, message);
  MIST_ASSERT(cnt >= 0)
  snprintf(buffer, std::min(static_cast<size_t>(cnt + 1), sizeof(buffer)),
           print_fmt, filename, line_number, func_name, check, message);
  throw ErrorType(buffer);
}

template <class ErrorType>
inline void assertionImpl(const char *check, const std::string &message,
                          const char *filename, const int line_number,
                          const char *func_name) {
  assertionImpl<ErrorType>(check, message.c_str(), filename, line_number,
                           func_name);
}
} // namespace mist::base

#define MIST_EXPECT_IMPL_(check, ErrorType, message)                           \
  do {                                                                         \
    if (MIST_UNLIKELY(!(check))) {                                             \
      ::mist::base::assertionImpl<ErrorType>(#check, message, __FILE__,        \
                                             __LINE__, __PRETTY_FUNCTION__);   \
    }                                                                          \
  } while (0);

// Macros that will throw an exception if check fails, no matter the build type
// is. If ErrorType is not provided, AssertionError will be thrown. It will
// print out file name, line number, function name, check criteria and error
// message.
//
// Usage:
// MIST_EXPECT_RT(1 == 2)
// MIST_EXPECT_RT(1 == 2, "what?")
// MIST_EXPECT_RT(1 == 2, std::runtime_error, "what?")
//
// terminate called after throwing an instance of 'std::runtime_error'
//  what():  (ommited)/mist/app/main.cc:8: int main(): 1 == 2 failed, what?
//
#define MIST_EXPECT_RT(...) MIST_OVERLOAD(MIST_EXPECT_RT, __VA_ARGS__)
#define MIST_EXPECT_RT_1(check)                                                \
  MIST_EXPECT_IMPL_(check, ::mist::base::AssertionError, "")
#define MIST_EXPECT_RT_2(check, message)                                       \
  MIST_EXPECT_IMPL_(check, ::mist::base::AssertionError, message)
#define MIST_EXPECT_RT_3(check, ErrorType, message)                            \
  MIST_EXPECT_IMPL_(check, ErrorType, message)

// Macros that will throw an exception if check fails only in
// Debug build
//
// Usage:
// MIST_EXPECT_D(1 == 2)
// MIST_EXPECT_D(1 == 2, "what?")
// MIST_EXPECT_D(1 == 2, std::runtime_error, "what?")
//
#ifdef MIST_NO_DEBUG
#define MIST_EXPECT_D(...)
#else
#define MIST_EXPECT_D(...) MIST_OVERLOAD(MIST_EXPECT_D, __VA_ARGS__)
#define MIST_EXPECT_D_1(check)                                                 \
  MIST_EXPECT_IMPL_(check, ::mist::base::AssertionError, "")
#define MIST_EXPECT_D_2(check, message)                                        \
  MIST_EXPECT_IMPL_(check, ::mist::base::AssertionError, message)
#define MIST_EXPECT_D_3(check, ErrorType, message)                             \
  MIST_EXPECT_IMPL_(check, ErrorType, message)
#endif

// Macros that unconditionally throw an exception with location information
//
// Usage:
//
// MIST_THROW_WITH_LOC(std::runtime_error, "what?")
//
// terminate called after throwing an instance of 'std::runtime_error'
//  what():  (ommited)/mist/app/main.cc:8: int main(): what?
namespace mist::base {

template <class ErrorType>
void inline throwWithLoc(const char *message, const char *filename,
                         const int line_number, const char *func_name) {
  // 128^2
  char buffer[16384];
  const char *print_fmt = "%s:%d: %s: %s";
  const auto cnt = snprintf(nullptr, 0, print_fmt, filename, line_number,
                            func_name, message);
  MIST_ASSERT(cnt >= 0)
  snprintf(buffer, std::min(static_cast<size_t>(cnt + 1), sizeof(buffer)),
           print_fmt, filename, line_number, func_name, message);
  throw ErrorType(buffer);
}

template <class ErrorType>
void inline throwWithLoc(const std::string &message, const char *filename,
                         const int line_number, const char *func_name) {
  throw_with_loc<ErrorType>(message.c_str(), filename, line_number, func_name);
}

} // namespace mist::base

#define MIST_THROW_WITH_LOC(ErrorType, message)                                \
  ::mist::base::throwWithLoc<ErrorType>(message, __FILE__, __LINE__,           \
                                        __PRETTY_FUNCTION__);
