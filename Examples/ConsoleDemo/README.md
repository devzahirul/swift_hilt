ConsoleDemo (SwiftHilt + Pure Swift)
===================================

What it shows
- Registering singletons and scoped services in a standalone Container
- Qualifiers (Named("base")) to distinguish multiple bindings of the same type
- Multibindings via registerMany/resolveMany
- Global facade usage (useContainer, resolve)
- Task-local environment + @Inject without passing the container explicitly
- Optional DAG recording (Graphviz DOT output)

Run
- From this directory: `swift run ConsoleDemo`
- With DOT: `swift run ConsoleDemo --dot`

Code
- `Package.swift` – local package that depends on the root SwiftHilt package via `.package(path: "../../")`
- `Sources/ConsoleDemo/main.swift` – annotated example code

Notes
- This demo is self-contained and does not modify the root Package.swift.
- You can copy/paste this pattern into server-side Swift or CLI tools.

