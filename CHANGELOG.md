## 0.4.3

- Reworked schema template for precise child element validation. Context-restricted elements (`param`, `Entry`, `Item`, `else`) are now validated only where they're actually allowed.
- Added hover documentation to all built-in elements and their attributes in the generated schema. Includes links to full reference docs.
- Added `schema.documentationFormat` option in `xwidget_config.yaml` (`cdata` or `html`). Use `html` for better hover rendering in IntelliJ-based IDEs.
- Added `--schema-docs` CLI flag to override `schema.documentationFormat` per invocation.
- Fixed path resolution for `xwidget_builder` when added as a relative path dependency (`path: ../../` in `pubspec.yaml`).
- Fixed schema compatibility with strict XSD validators (e.g. xmllint).

## 0.4.2

- Fixed inflation of nested parameterized collections (`List<List<Widget>>`,
  `List<Map<String, String>>`, etc.). Added `castElement` callback to `addArg`
  that recursively casts inner elements during argument resolution. The inflater
  generator now emits `_buildCastExpression` lambdas for arbitrary nesting depth.
- Simplified `<builder>` returnType enumeration from `Widget`, `Widget?`, `List:Widget`,
  `List:PopupMenuEntry` to `List` and `SingleChild`.

## 0.4.1

- Fixed collection return types in function adapters. Parameterized collections
  (`List`, `Set`, `Iterable`, `Map`) now use `.cast<>()` instead of `as` to satisfy
  Dart's reified generics.

## 0.4.0

- **BREAKING:** Requires `xwidget` 0.4.0. Both packages must be upgraded together.
- Fixed Dart 3.4 function type compatibility issue with `Function`-typed constructor parameters.
- Added `addFnArg` to `InflaterArgs` for typed function adapter wrapping.
- Inflater generator now emits typed adapter lambdas for all `Function`-typed parameters.
- Fixed duplicate class handling in inflater spec via deduplication.

## 0.3.1

- Fixed `xc init --new-app` not copying `fragment/count.xml` to the resources folder

## 0.3.0

- Cloud management CLI — deploy, promote, and manage workspaces, projects, channels, and deployments via `xc cloud`.
- Analytics CLI — query render, download, error, and page transition data via `xc analytics`.
- Project key rotation with configurable grace periods (0–90 days).
- `xc` top-level CLI entry point for all XWidget Builder commands.
- Full documentation site at docs.xwidget.dev.
- Updated minimum Dart SDK to 3.8.

## 0.2.1

* Resolved major pain points with default values and imports. Constructor defaults now
  delegate to the underlying widget, and imports are automatically resolved through
  export analysis. Manual overrides in `xwidget_config.yaml` remains available for edge cases.
* Fixed issue with the source analyzer not recognizing library parts
* Improved inflater error messages

## 0.2.0

### **Breaking Changes**

* Increased Flutter version constraint from >=1.17.0 to >=3.10.0
* Decreased Dart SDK constraint from >=3.4.4 to >=3.0.0
* Fixed bug with dependency versioning
* Fixed builder tests

## 0.1.2

* Fixed several issues with project initialization scripts

## 0.1.1

* Added example usage
* Updated package description

## 0.1.0

* Initial release.