#pragma once

#include <fmt/core.h>

#include <functional>
#include <memory>
#include <string>
#include <type_traits>
#include <unordered_map>

#include "mist/base/error.h"

namespace mist::base {
template <class RegistryType> class Registry {
public:
  template <class T> static RegistryType &set() {
    if (data().find(T::type) == data().end()) {
      data().insert({T::type, RegistryType()});
    }
    return data().at(T::type);
  }

  static const RegistryType &get(const std::string &name) {
    MIST_EXPECT_RT(data().find(name) != data().end());
    return data().find(name)->second;
  }

private:
  Registry() {}

  static std::unordered_map<std::string, RegistryType> &data() {
    static std::unordered_map<std::string, RegistryType> data;
    return data;
  }
};

// Automatically register class for easy construction from configration files
//
//
// @tparam Key: registration key type
// @tparam Base: base class type for registered class
// @tparam Args: arguments to construct the class
//
//
// We include to key type here for potential future use on protobuf
template <class Key, class Base, class... Args> class TypeRegistry {
  using KeyType = Key;
  using BaseType = Base;
  using CreatorType = std::function<BaseType *(Args &&...)>;

public:
  // Requirement:
  // (1) Derived is a derived class of Base
  // (2) Derived can be constructed from Args
  template <class Derived>
    requires std::is_base_of_v<BaseType, Derived> &&
             std::is_constructible_v<Derived, Args &&...>
  struct RawCreatorType {
    RawCreatorType(Key key) {
      const auto it =
          TypeRegistry<Key, Base, Args...>::instance().factory().insert(
              {key, [](Args &&...args) {
                 return new Derived(std::forward<Args>(args)...);
               }});
      MIST_EXPECT_RT(
          it.second,
          fmt::format("Failed to register factory method for {}", key));
    }
  };

  // retrive the unique object representing the registry type
  static TypeRegistry &instance() {
    static TypeRegistry registry;
    return registry;
  }

  BaseType *create(KeyType key, Args &&...args) const {
    const auto it = factory_.find(key);
    MIST_EXPECT_RT(
        it != factory_.end(),
        fmt::format("Cannot find registered factory method for {}", key));
    return it->second(std::forward<Args>(args)...);
  }

  [[nodiscard]] bool isRegistered(KeyType key, Args &&.../* args */) const {
    return factory_.find(key) != factory_.end();
  }

private:
  std::unordered_map<KeyType, CreatorType> &factory() { return factory_; }
  TypeRegistry() = default;
  ~TypeRegistry() = default;

  std::unordered_map<KeyType, CreatorType> factory_;
};

// To avoid implicit conversion, we require to specify key type in the template
// instead of relying on automatic deduction
template <class Key, class Base, class... Args>
[[nodiscard]] inline bool isClassRegistered(Key key, Args &&...args) {
  return TypeRegistry<Key, Base, Args...>::instance().isRegistered(
      key, std::forward<Args>(args)...);
}

template <class Key, class Base, class... Args>
inline Base *createRawPtr(Key key, Args &&...args) {
  return TypeRegistry<Key, Base, Args...>::instance().create(
      key, std::forward<Args>(args)...);
}

template <class Key, class Base, class... Args>
inline std::unique_ptr<Base> createUniquePtr(Key key, Args &&...args) {
  return std::unique_ptr<Base>(
      TypeRegistry<Key, Base, Args...>::instance().create(
          key, std::forward<Args>(args)...));
}

} // namespace mist::base

//
//
// Example of usage
//
// in "Base.h"
//
// struct Base {
//   virtual ~Base() {};
//   virtual std::string getName() const = 0;
// };
//
// in "Derived.cc"
//
// struct Derived {
//   Derived() = default;
//   Derived(std::string name) : name_(std::move(name)) {}
//   std::string getName() const {
//     return name_;
//   }
//
//   std::string name_ {"Derived"};
// };
//
// MIST_REIGSTER_CLASS(std::string, "Derived", Base, Derived)
// MIST_REGISTER_CLASS(std::string, "Derived", Base, Derived, std::string)
//
// in "CMakeLists.txt" (CRITICAL! for other libraries to find the symbol)
//
// mist_library_registry(library_name)
//
//
// in other modules, one can check if the factory method is registred or not
//
// isClassRegistered<std::string, Base>("Derived") --> return true
// isClassRegistered<std::string, Base>("Derived", "test") --> return true
// isClassRegistered<std::string, Base>("Derived", 1) --> return false
//
// One can also get a ptr (raw/unique)
// auto ptr = createRawPtr<std::string, Base>("Derived") --> Derived::Derived()
// ptr->getName() --> return "Derived"
//
// auto ptr = createRawPtr<std::string, Base>("Derived", "Hello World") -->
// Derived::Derived(std::string) ptr->getName() --> return "Hello World"
//
// auto ptr = createRawPtr<std::string, Base>("Derived", "Hello World",
// "Whoops") --> will throw since we don't register this factory

// NOTE: (1) those macros should ONLY be used inside source file to avoid being
// included in multiple translation units, resulting in duplicated registration
// (2) those macros should NOT be placed inside anonymous namespace. We need
// external linkage

#define MIST_REGISTRY_VAR_NAME MIST_CAT(MistGlobalRegistry_Class, __COUNTER__)

#define MIST_REGISTER_CLASS(KeyType, key, BaseType, DerivedType, ...)          \
  ::mist::base::TypeRegistry<KeyType, BaseType __VA_OPT__(, ) __VA_ARGS__>::   \
      RawCreatorType<DerivedType>                                              \
      MIST_REGISTRY_VAR_NAME(key)
