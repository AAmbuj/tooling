# Copyright (c) <YEAR> <COPYRIGHT HOLDER>
# SPDX-License-Identifier: Apache-2.0
# Destination: tools/coverage/BUILD   (root BUILD also needs: exports_files(["MODULE.bazel"]))

load("@score_tooling//coverage:defs.bzl", "score_coverage_reporter", "score_coverage_scope")

score_coverage_scope(
    name = "coverage_scope",
    testonly = True,
    deps = ["//:my_unit_lib"],  # production targets only
)

score_coverage_reporter(
    name = "reporter_wrapper",
    testonly = True,
    coverage_scope = ":coverage_scope",
    llvm_cov = "@llvm_toolchain//:llvm-cov",
    llvm_cxxfilt = "@llvm_toolchain_llvm//:bin/llvm-cxxfilt",
    llvm_profdata = "@llvm_toolchain//:llvm-profdata",
)
