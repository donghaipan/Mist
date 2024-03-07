#pragma once

#include <string>

namespace mist::registry_test {

class Base {
public:
  virtual ~Base() {}
  virtual int getValue() const = 0;
};

} // namespace mist::registry_test
