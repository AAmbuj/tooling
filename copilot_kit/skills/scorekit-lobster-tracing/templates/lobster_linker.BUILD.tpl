# Copyright (c) <YEAR> <COPYRIGHT HOLDER>
# SPDX-License-Identifier: Apache-2.0
# Destination: any BUILD (standalone source-code tracing, outside rules_score)

load("@score_tooling//lobster_bazel:lobster_bazel.bzl", "lobster_linker")

# Scans srcs/hdrs of the listed targets (transitively through deps) for
#   // lobster-trace: MyModule.COMP_001
# and emits <name>.lobster (LobsterProvider).
lobster_linker(
    name = "impl_trace",
    srcs = ["//:my_unit_lib"],
    namespace = "source",
    tracing_tags = ["lobster-trace"],
)
