# Page placement rules

A generated wrapper page is only a placeholder. Real prose belongs alongside your `.puml`
files, passed in the **same view attribute** (`static`, `dynamic`, `public_api`, `internal_api`).
What the generator does with your page is decided by its stem relative to the diagrams already
in that directory.

## The three behaviours

### Standalone

`<stem>.rst` / `<stem>.md` with **no** matching `<stem>.puml` in the same directory.

Becomes an ordinary extra entry in that directory's toctree. Use it for prose that is not about
one specific diagram — design rationale, an overview, background context.

### Override

`<stem>.rst` / `<stem>.md` next to a same-stem `<stem>.puml` / `<stem>.plantuml`.

Replaces that diagram's generated wrapper page outright. The `.puml` is still staged as a
sibling, so embed it yourself:

```rst
Public API
==========

The SEooC exposes exactly one operation, ``GetNumber()``, on ``SampleLibraryAPI``.

.. uml:: public_api.puml
   :align: center
   :alt: SEooC example public API
```

Use it when you want narrative directly around one specific diagram instead of it rendering bare.

### Compose

`index.rst` / `index.md`.

Your content renders *above* the generated directory-level toctree, which is otherwise left
untouched — every diagram in that directory keeps its navigation entry. Your title becomes the
index page's title. Use it for a directory-level introduction that must not hide any diagram
from the navigation.

## Hard errors

- A `.puml` / `.plantuml` whose own stem is literally `index` is rejected at analysis time.
  That stem is reserved for the generated navigation page — rename the diagram.
- Two files that would stage at the same relative path (for example both a `.rst` and a `.md`
  for the same stem) fail the build with a message naming both conflicting sources.

## View roots

Each view's top-level index is the single toctree entry surfaced on the enclosing
`dependable_element` page for that view. A directory containing exactly one page and nothing
else gets no generated index at all — that page becomes the view's root.

## Working demonstration

[`bazel/rules/rules_score/examples/seooc/design/`](../../../../bazel/rules/rules_score/examples/seooc/design) — `index.md` composes an introduction above
the static view's root navigation, and `public_api.rst` overrides the generated wrapper for
`public_api.puml`.

Authoritative prose: [`bazel/rules/rules_score/docs/user_guide/architectural_design.rst`](../../../../bazel/rules/rules_score/docs/user_guide/architectural_design.rst),
section "Authoring pages alongside diagrams".
