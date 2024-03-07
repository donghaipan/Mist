#include "mist/base/grade.h"
#include "gtest/gtest.h"

namespace mist::base {

struct GradeTest : public ::testing::Test {};

constexpr bool isStrEqual(const char *lhs, const char *rhs) {
  return std::string_view(lhs) == rhs;
}

constexpr auto sumOfAllValues() {
  using UnderlyingType = std::underlying_type_t<Grade::Type>;
  UnderlyingType s = 0;
  for (auto v : Grade::allValues()) {
    s += static_cast<UnderlyingType>(Grade::Type(v));
  }
  return s;
}

TEST_F(GradeTest, test_enum_constexpr_functionality) {
  static_assert(Grade::toString(Grade::A) == "A");
  static_assert(Grade::isValid(Grade::A));
  static_assert(Grade::parseFrom(1) == Grade::A);
  static_assert(Grade::allValues().size() == 4);
  static_assert(isStrEqual(Grade::c_str(Grade::A), "A"));
  static_assert(!Grade::isValid(Grade::parseFrom(0)));

  constexpr Grade type{Grade::A};

  static_assert(type.isValid());
  static_assert(type.toString() == "A");
  static_assert(isStrEqual(type.c_str(), "A"));

  static_assert(static_cast<Grade>(type) == Grade::A);
  static_assert(type == Grade::A);
  static_assert(type != Grade::B);

  static_assert(toString(type) == "A");
  static_assert(toString(Grade::A) == "A");

  static_assert(sumOfAllValues() == 10);
}

} // namespace mist::base
