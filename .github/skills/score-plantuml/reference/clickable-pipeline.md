# Clickable PlantUML pipeline

Rendered diagrams become navigable: clicking a component in an overview diagram jumps to the
page that elaborates it. Authors do not write links — they are derived. Your only job is to
give elements correct aliases and consistent FQNs.

## Stages

1. **Parse & resolve.** `puml_cli` expands `!include`s, parses the diagram, and resolves every
   alias to a fully qualified name by walking the package/component nesting.
2. **ID map.** With `--idmap-output-dir`, the parser writes `<stem>.idmap.json` next to the
   other outputs, classifying each element as a *define* (elaborated here) or a *reference*
   (mentioned as a leaf or relation endpoint).

   ```json
   {
     "source": "seooc/design/static_design.puml",
     "defines": [
       { "alias": "component_example", "id": "safety_software_seooc_example.component_example" },
       { "alias": "unit_1", "id": "safety_software_seooc_example.component_example.unit_1" }
     ],
     "references": [
       { "alias": "SampleLibraryAPI", "id": "SampleLibraryAPI" }
     ]
   }
   ```

   `source` comes from `--source-name` and must be the stable workspace-relative path, otherwise
   cross-diagram matching fails.
3. **Sphinx injection.** The `clickable_plantuml` extension
   ([`plantuml/sphinx/clickable_plantuml/clickable_plantuml.py`](../../../../plantuml/sphinx/clickable_plantuml/clickable_plantuml.py)) scans the source tree for
   `*.idmap.json`, builds an index from id → defining source, and for every diagram node
   rewrites the `uml` block before `sphinxcontrib-plantuml` renders it:

   ```plantuml
   url of component_example is [[../component_detail.html]]
   url of unit_1 is [[unit_design/unit_1.html#unit-1-class-diagram]]
   ```

## Matching and tiebreaks

For each element referenced in a diagram, the extension looks up its FQN in the definition index:

1. Exactly one defining source → link it.
2. Several candidates → prefer the one with the longest common path prefix with the current
   document (proximity).
3. Still tied → prefer the file that elaborates more of that id's decomposition.
4. Still tied → log a warning and emit no link. Wrong links are never guessed.
5. A diagram is never linked to itself.

Only aliases matching `[a-zA-Z_][a-zA-Z0-9_]*` receive links. Characters significant to PlantUML
are percent-encoded in the URL; the `#` fragment separator is preserved.

## Author checklist

- Give every element an alias that is a valid identifier — no spaces, no dots, no hyphens.
- Keep nesting identical across diagrams so FQNs agree; a mismatch produces no link, not an error.
- Elaborate a given element in exactly one diagram. Mentioning it elsewhere as a leaf is what
  makes the link appear.
- If an expected link is missing, build the docs with warnings visible and look for the
  ambiguity warning from `clickable_plantuml`.
