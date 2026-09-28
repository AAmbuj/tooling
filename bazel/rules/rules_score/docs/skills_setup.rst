..
   # *******************************************************************************
   # Copyright (c) 2026 Contributors to the Eclipse Foundation
   #
   # See the NOTICE file(s) distributed with this work for additional
   # information regarding copyright ownership.
   #
   # This program and the accompanying materials are made available under the
   # terms of the Apache License Version 2.0 which is available at
   # https://www.apache.org/licenses/LICENSE-2.0
   #
   # SPDX-License-Identifier: Apache-2.0
   # *******************************************************************************

Copilot Skills Setup
====================

``score_tooling`` ships shared GitHub Copilot customizations that document how
to use ``rules_score``: a set of **skills** (``score-*`` directories under
``.github/skills``), a **router agent** (``score-*.agent.md`` files under
``.github/agents``) and task **prompts** (``score-*.prompt.md`` files under
``.github/prompts``). Downstream repositories pull these into their own
``.github`` directory so the same guidance is available to Copilot locally,
without re-deriving it from the rule sources on every prompt.

Wiring
------

Declare the dependency and call the macro from the repository root ``BUILD``
file (the package next to ``.github``):

.. code-block:: starlark

   load("@score_tooling//skills_sync:sync_skills.bzl", "sync_skills")

   sync_skills()

Targets
-------

- ``bazel run //:sync_skills`` — copies score_tooling's current ``score-*``
  skills into the local ``.github/skills`` directory, its
  ``score-*.agent.md`` agents into ``.github/agents`` and its
  ``score-*.prompt.md`` prompts into ``.github/prompts``, overwriting outdated
  copies and removing assets that score_tooling no longer ships. Commit the
  result.
- ``bazel test //:sync_skills.check`` — fails if the committed assets are
  missing, outdated, or stale relative to the ``score_tooling`` version in
  use. Wire this into CI so upstream updates are caught automatically.

What you get
------------

.. list-table::
   :header-rows: 1

   * - Asset
     - Purpose
   * - ``.github/agents/score-tooling.agent.md``
     - Router agent. Classifies a task and loads exactly one skill, so a
       prompt never pulls in unrelated guidance.
   * - ``score-safety-analysis-review`` (prompt)
     - Reviews an existing FMEA for coverage, traceability and reasoning
       quality; reports findings by severity without editing files.
   * - ``score-safety-analysis-rollout`` (prompt)
     - Walks the public API with HAZOP guide words, confirms the safety
       judgements, then writes the records, FTAs and BUILD wiring.
   * - ``score-requirements``
     - Requirement content, levels, ASIL, allocation, traceability chain.
   * - ``score-trlc``
     - TRLC and ``.rsl`` syntax, the ``ScoreReq`` field tables, parse errors.
   * - ``score-architecture``
     - Component/unit decomposition, ``architectural_design`` wiring,
       validators.
   * - ``score-plantuml``
     - ``.puml`` authoring conventions, the parser CLI, clickable diagrams.
   * - ``score-testing``
     - GoogleTest traceability annotation and ``test_case_coverage.lock.yaml``.
   * - ``score-safety-analysis``
     - FMEA, ``FailureMode`` / ``ControlMeasure`` records, FTA trees.
   * - ``score-docs``
     - ``.rst`` authoring, page placement next to diagrams, ``glossary``.
   * - ``score-onboarding``
     - ``MODULE.bazel`` wiring, toolchains, scaffolding the first SEooC.

VS Code discovers ``.github/skills``, ``.github/agents`` and ``.github/prompts``
automatically; no editor configuration is required beyond reloading the window
after the first sync.

Offline pack
------------

Not every consumer builds with Bazel. ``//.github:copilot_pack`` produces a
self-contained archive carrying the same agent and skills plus an installer,
with no network, Bazel or ``score_tooling`` dependency at install time:

.. code-block:: bash

   bazel build //.github:copilot_pack
   tar -xzf bazel-bin/.github/score-copilot-pack.tar.gz
   cd score-copilot-pack

   ./install.sh                            # ~/.copilot/{agents,skills}
   ./install.sh --workspace /path/to/repo  # <repo>/.github/{agents,skills}

Installing into ``~/.copilot`` makes the assets available in every workspace on
that machine. The installer overwrites in place and removes ``score-*`` assets
that the pack no longer contains, so re-running it with a newer archive is the
update path. Full end-user instructions ship as ``INSTALL.md`` inside the pack.

Naming convention
-----------------

Only skill directories, agent files and prompt files whose names start with
``score-`` are distributed. Anything else under ``.github/skills``,
``.github/agents`` or ``.github/prompts`` stays local to the repository that
defines it.
