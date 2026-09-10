#!/usr/bin/env bash
# Run with: nix run .#codex-tools -- bash test/toolchain-smoke.sh
# Uses disposable projects; no registry downloads are needed.
set -euo pipefail

work_dir=$(mktemp -d -t agent-toolchain-smoke.XXXXXXXX)
trap 'rm -rf "$work_dir"' EXIT

commands=(
  gcc g++ clang clang++ clangd clang-format clang-tidy cppcheck
  cmake ctest ninja meson make autoconf automake libtool bison flex
  ld.lld llvm-cov llvm-profdata bear ccache conan cmake-format
  gdb lldb valgrind gcovr lcov doxygen dot pkg-config
  python3 pip uv pytest coverage cython nox tox virtualenv
  ruff basedpyright black isort mypy pylint bandit pip-audit py-spy
  cargo rustc rust-analyzer rustfmt cargo-clippy cargo-miri
  cargo-nextest cargo-audit cargo-semver-checks cargo-objdump cargo-bloat
  cargo-deny cargo-add cargo-expand cargo-flamegraph cargo-fuzz cargo-hack
  cargo-llvm-cov cargo-machete cargo-mutants cargo-outdated cargo-public-api
  cargo-tarpaulin cargo-udeps cargo-watch sccache
  hyperfine strace patchelf pre-commit shellcheck shfmt
  jq node gh tesseract pdftotext adb java modal
)
for command in "${commands[@]}"; do
  command -v "$command" >/dev/null || {
    echo "Missing command: $command" >&2
    exit 1
  }
done
printf 'Found %s required commands.\n' "${#commands[@]}"
modal --version
python3 -c 'import modal; app = modal.App("local-toolchain-smoke"); print("Modal SDK", modal.__version__)'
test -f "$LIBCLANG_PATH/libclang.so"
pkg-config --exists openssl fmt spdlog zlib

mkdir -p "$work_dir/cpp"
cat >"$work_dir/cpp/CMakeLists.txt" <<'CMAKE'
cmake_minimum_required(VERSION 3.20)
project(agent_toolchain_smoke LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
find_package(Catch2 3 REQUIRED)
find_package(GTest REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(Boost CONFIG REQUIRED)
find_package(fmt REQUIRED)
find_package(spdlog REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(ZLIB REQUIRED)
enable_testing()
add_executable(smoke main.cpp)
target_link_libraries(smoke PRIVATE Catch2::Catch2WithMain Eigen3::Eigen
  Boost::headers fmt::fmt spdlog::spdlog OpenSSL::Crypto ZLIB::ZLIB)
add_test(NAME smoke COMMAND smoke)
add_executable(gtest_smoke gtest.cpp)
target_link_libraries(gtest_smoke PRIVATE GTest::gtest_main)
add_test(NAME gtest_smoke COMMAND gtest_smoke)
CMAKE
cat >"$work_dir/cpp/main.cpp" <<'CPP'
#include <boost/algorithm/string.hpp>
#include <catch2/catch_test_macros.hpp>
#include <Eigen/Core>
#include <fmt/format.h>
#include <openssl/crypto.h>
#include <spdlog/spdlog.h>
#include <zlib.h>
#include <string>
TEST_CASE("native libraries compile and link") {
    std::string text = "toolchain";
    boost::to_upper(text);
    REQUIRE(text == "TOOLCHAIN");
    REQUIRE(Eigen::Vector2i(2, 3).sum() == 5);
    REQUIRE(fmt::format("{}", 42) == "42");
    REQUIRE(OpenSSL_version_num() != 0);
    REQUIRE(zlibVersion() != nullptr);
    spdlog::info("Native toolchain works");
}
CPP
cat >"$work_dir/cpp/gtest.cpp" <<'CPP'
#include <gtest/gtest.h>
TEST(Toolchain, Arithmetic) { EXPECT_EQ(2 + 3, 5); }
CPP
for compiler in g++ clang++; do
  build_dir="$work_dir/build-$compiler"
  cmake -S "$work_dir/cpp" -B "$build_dir" -G Ninja \
    -DCMAKE_CXX_COMPILER="$compiler" -DCMAKE_BUILD_TYPE=Debug
  cmake --build "$build_dir" --parallel 2
  ctest --test-dir "$build_dir" --output-on-failure
done
valgrind --quiet --error-exitcode=1 --leak-check=full "$work_dir/build-g++/smoke"
clang-tidy -p "$work_dir/build-clang++" "$work_dir/cpp/main.cpp" --quiet

mkdir -p "$work_dir/python"
cat >"$work_dir/python/arithmetic.py" <<'PY'
def add(a: int, b: int) -> int:
    return a + b
PY
cat >"$work_dir/python/test_arithmetic.py" <<'PY'
import asyncio

import pytest
from hypothesis import given
from hypothesis import strategies as st

from arithmetic import add


@given(st.integers(), st.integers())
def test_add(a: int, b: int) -> None:
    assert add(a, b) == add(b, a)


@pytest.mark.asyncio
async def test_async() -> None:
    await asyncio.sleep(0)
    assert add(2, 3) == 5


def test_mock(mocker) -> None:
    callback = mocker.Mock(return_value=5)
    assert callback() == 5
    callback.assert_called_once()
PY
(
  cd "$work_dir/python"
  python3 -c 'import build, coverage, Cython, debugpy, hypothesis, numpy, pandas, pybind11, scipy, setuptools, wheel'
  python3 -m pytest -q -n 2 --cov=arithmetic --cov-fail-under=100
  ruff check .
  mypy arithmetic.py
  basedpyright arithmetic.py
  uv venv --python "$(command -v python3)" .venv
  .venv/bin/python -c 'import sys; assert sys.prefix != sys.base_prefix'
)

cargo init --quiet --lib --vcs none --name toolchain_smoke "$work_dir/rust"
(
  cd "$work_dir/rust"
  cargo fmt --check
  cargo clippy --offline --all-targets -- -D warnings
  cargo nextest run --offline
  cargo llvm-cov --offline --fail-under-lines 100
  cargo machete
  cargo miri --version
  # Confirm the bundled cross-target standard libraries actually work.
  cargo check --offline --target wasm32-unknown-unknown
  printf '#![no_std]\npub fn add(a: u32, b: u32) -> u32 { a + b }\n' >embedded.rs
  rustc --crate-type lib --target thumbv7em-none-eabihf embedded.rs
)
printf 'C++, Python, and Rust toolchain smoke checks passed.\n'
