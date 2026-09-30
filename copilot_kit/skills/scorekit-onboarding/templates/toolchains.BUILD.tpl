# Copyright (c) <YEAR> <COPYRIGHT HOLDER>
# SPDX-License-Identifier: Apache-2.0
# Destination: bazel/toolchains/BUILD
#
# Needed by unit_design to parse the C++ implementation with libclang.

load("@score_tooling//cpp/libclang:libclang_toolchain.bzl", "libclang_toolchain")

libclang_toolchain(
    name = "my_libclang",
    cc_toolchain = "@llvm_toolchain//:cc-clang-x86_64-linux",
    libclang = "@llvm_toolchain_llvm//:lib/libclang.so",
)

toolchain(
    name = "my_libclang_toolchain",
    toolchain = ":my_libclang",
    toolchain_type = "@score_tooling//cpp/libclang:libclang_toolchain_type",
    visibility = ["//:__subpackages__"],
)
