#include "registry_dummy_base.h"

#include "mist/base/registry.h"

namespace mist::registry_test {

class Foo : public Base {
public:
  Foo() {}
  virtual int getValue() const final { return 0; }
};

class Bar : public Base {
public:
  Bar(int v) : v_(v) {}
  Bar(int x, int y) : v_(x + y) {}
  virtual int getValue() const final { return v_; }

private:
  int v_;
};

MIST_REGISTER_CLASS(std::string, "Foo", Base, Foo);
MIST_REGISTER_CLASS(std::string, "Bar", Base, Bar, int);
MIST_REGISTER_CLASS(std::string, "Bar", Base, Bar, int, int);

} // namespace mist::registry_test
