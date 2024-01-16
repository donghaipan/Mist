"""Enum generator script.

Input file should be in yaml format, with keys

namespace: str
enum_name: str
underlying_type: str
enum_entries: List[str]

Naming convention follows the README of the project.

Each item of enum_entries can be either name only, or name with value separated by comma.
But items should be either all with value or all without value. For example, the followings
are valid

enum_entries:
  - CALL
  - PUT

enum_entries:
  - CALL, 1
  - PUT, 2

but a mixed style is not valid:

enum_entries:
  - CALL
  - PUT, 2

Values can only be int. Using char is not supported:

enum_entries:
  - CALL, 'c'
  - PUT, 'p'
"""
import argparse
import sys
from pathlib import Path
from typing import List, Tuple, Union
from typing_extensions import Self  # will be in typing after Python 3.11

import yaml
import chevron
from pydantic import BaseModel, validator

TEMPLATE = """// This file is automatically generated from enum_generator.py.
#pragma once

#include <array>
#include <fmt/ostream.h>
#include <ostream>
#include <stdexcept>
#include <string_view>
#include <type_traits>

namespace {{namespace}} {
class {{enum_type}} {
 public:
  enum class Type : {{underlying_type}} {
    {{enum_to_value}}
  };
  using enum Type;
  // Allow implicit conversion from {{enum_type}}::Type to {{enum_type}}
  constexpr {{enum_type}}(Type v) noexcept : value_(v) {}
  constexpr static std::string_view toString(Type v) noexcept {
    switch (v) {
    {{{switch_enum_to_str}}}
    default:
      return "UNKNOWN";
    }
  }
  constexpr static const char *c_str(Type v) noexcept {
    switch (v) {
    {{{switch_enum_to_str}}}
    default:
      return "UNKNOWN";
    }
  }
  [[nodiscard]] constexpr static bool isValid(Type v) noexcept {
    switch (v) {
    {{{switch_enum_to_true}}}
    default:
      return false;
    }
  }
  constexpr static std::array<{{enum_type}}, {{enum_count}}> allValues() noexcept {
    return { {{enums}} };
  }
  static Type parseFrom(std::string_view sv) {
    {{{enum_str_to_type}}}
    throw std::runtime_error("Unknown enum " + std::string(sv));
  }
  template <class T>
  requires std::is_convertible_v<T, std::underlying_type_t<Type>>
  constexpr static Type parseFrom(T t) noexcept {
    return static_cast<Type>(static_cast<std::underlying_type_t<Type>>(t));
  }
  constexpr std::string_view toString() const noexcept {
    return {{enum_type}}::toString(value_);
  }
  [[nodiscard]] constexpr bool isValid() const noexcept {
    return {{enum_type}}::isValid(value_);
  }
  constexpr const char* c_str() const noexcept {
    return {{enum_type}}::c_str(value_);
  }
  explicit constexpr operator Type() const noexcept {
    return value_;
  }
  friend constexpr bool operator==({{enum_type}} lhs, {{enum_type}} rhs) noexcept {
    return lhs.value_ == rhs.value_;
  }
  friend constexpr bool operator!=({{enum_type}} lhs, {{enum_type}} rhs) noexcept {
    return !(lhs == rhs);
  }
 private:
  Type value_;
};
constexpr std::string_view toString({{enum_type}} t) noexcept {
  return t.toString();
}
constexpr std::string_view toString({{enum_type}}::Type t) noexcept {
  return {{enum_type}}::toString(t);
}
inline std::ostream& operator<<(std::ostream& os, {{enum_type}} t) {
  return os << t.toString();
}
inline std::ostream& operator<<(std::ostream& os, {{enum_type}}::Type t) {
  return os << {{enum_type}}::toString(t);
}
}  // namespace {{namespace}}

template<>
struct fmt::formatter<::{{namespace}}::{{enum_type}}>
    : fmt::ostream_formatter {};

namespace std {
template<>
struct hash<::{{namespace}}::{{enum_type}}> {
  std::size_t operator()(::{{namespace}}::{{enum_type}} t) noexcept {
    return hash<::{{namespace}}::{{enum_type}}::Type>{}(
        static_cast<::{{namespace}}::{{enum_type}}::Type>(t));
  }
};
}  // namespace std
"""


SINGLE_ENTRIES = List[Tuple[str]]
VALUE_ENTRIES = List[Tuple[str, int]]


def _validate_string(s: str, label: str):
    if not s:
        raise ValueError(f"{label} must not be empty string")

    if " " in s:
        raise ValueError(f"{label} must not contain white space, got {s!r}")
    return s


class EnumSchema(BaseModel):
    namespace: str
    enum_name: str
    underlying_type: str
    enum_entries: Union[SINGLE_ENTRIES, VALUE_ENTRIES]

    @classmethod
    def parse_from_file(cls, input_file: Path) -> Self:
        if not input_file.exists():
            raise ValueError("Cannot find input file %s" % input_file.as_posix())

        with open(input_file, "r") as file:
            pars = yaml.safe_load(file)

        pars["enum_entries"] = [
            tuple(item.strip() for item in entry.split(","))
            for entry in pars["enum_entries"]
        ]
        return EnumSchema(**pars)

    def is_single_entry(self) -> bool:
        return len(self.enum_entries[0]) == 1

    @validator("namespace")
    def namespace_validation(cls, v):
        if not v.islower():
            raise ValueError(f"namespace must be all lower case, got {v!r}")
        return _validate_string(v, "namespace")

    @validator("enum_name")
    def enum_name_validation(cls, v):
        return _validate_string(v, "enum_name")

    @validator("underlying_type")
    def underlying_type_validation(cls, v):
        return _validate_string(v, "underlying_type")

    @validator("enum_entries")
    def enum_entries_validation(cls, v):
        if not v:
            raise ValueError("enum_entries should not be empty")
        n_entries = len(v)

        for entry in v:
            if not entry[0].isupper():
                raise ValueError(
                    f"enum item must be all upper letter, got {entry[0]!r}"
                )

        unique_items = {entry[0] for entry in v}
        if len(unique_items) != n_entries:
            raise ValueError("duplicate items found in enum")

        if len(v[0]) == 2:
            unique_values = {entry[1] for entry in v}
            if len(unique_values) != n_entries:
                raise ValueError("duplicate values found in enum")
        return v


def generate(schema: EnumSchema):
    enum_entries = schema.enum_entries

    if schema.is_single_entry():
        enum_to_value = ",\n    ".join(f"{item[0]}" for item in enum_entries)
    else:
        enum_to_value = ",\n    ".join(
            f"{item[0]} = {item[1]}" for item in enum_entries
        )

    kwargs = {
        "namespace": schema.namespace,
        "underlying_type": schema.underlying_type,
        "enum_type": schema.enum_name,
        "enum_to_value": enum_to_value,
        "enums": ", ".join(item[0] for item in enum_entries),
        "switch_enum_to_str": "\n    ".join(
            f'case {item[0]}:\n      return "{item[0]}";' for item in enum_entries
        ),
        "switch_enum_to_true": "\n    ".join(
            f"case {item[0]}:\n      return true;" for item in enum_entries
        ),
        "enum_str_to_type": "\n    ".join(
            f'if (sv == "{item[0]}") {{ return {item[0]}; }}' for item in enum_entries
        ),
        "enum_count": len(schema.enum_entries),
    }
    return chevron.render(TEMPLATE, kwargs, warn=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=str, required=True, help="input file")
    parser.add_argument("--output", type=str, required=True, help="output file")

    args = parser.parse_args()

    input_file = Path(args.input)

    schema = EnumSchema.parse_from_file(input_file)

    output_file = Path(args.output)
    if not output_file.parent.exists():
        output_file.parent.mkdir(parents=True, exist_ok=True)

    success = True
    with open(output_file, "w") as file_writer:
        try:
            file_writer.write(generate(schema))
        except Exception as e:
            sys.stderr.write(
                "Failed to generate enum for %s, error %s\n"
                % (input_file.as_posix(), e)
            )
            success = False

    if not success:
        # remove the file
        output_file.unlink()
        raise ValueError("Error generating enum occurred")


if __name__ == "__main__":
    main()