## 0.5.4

- Updated the generated schema documentation for `<callback>` to match the corrected runtime
  behavior: `returnVar` is always stored in the surrounding `Dependencies` (independent of
  `dependenciesScope`), and `dependenciesScope` controls only how `action` is evaluated, not
  where `returnVar` is stored.

## 0.5.3

- Added `keepAlive` to the built-in `Controller` schema element so XML schema validation and IDE completion match the runtime controller attribute.
- Updated the default schema config to stop excluding `*:child` attributes globally.

## 0.5.2

- Controller code generation now registers factories by explicit class name via
  `registerControllerFactoryForName()`.
- Fixes generated controller registration for dart2js/minified web builds.
- Removed `import_cache.json` output.

## 0.5.1

- Controller code generation now skips abstract classes.

## 0.5.0

- **BREAKING:** Config schema changes in `xwidget_config.yaml`. The `resources:` group has been removed; use top-level `fragmentsPath` and `valuesPath` keys instead. See the [upgrade guide](https://docs.xwidget.dev/builder/upgrade-guide/) for migration steps.
- Added a registry builder that generates a single `registry.g.dart` exporting a `registerXWidgetComponents()` function. Users call this one function from `main.dart` instead of calling `registerXWidgetIcons()`, `registerXWidgetInflaters()`, and `registerXWidgetControllers()` manually. Requires `xwidget` 0.5.0 or newer; on older `xwidget` the registry is skipped and existing manual-registration patterns continue to work.
- Added `registry:` section in `xwidget_config.yaml` with a `target:` key controlling the output path (defaults to `lib/xwidget/generated/registry.g.dart`).
- Registry generation runs after every `generate` invocation regardless of the `--only` flag, so the registry stays in sync with whatever other generated files exist.
- Orphaned generated files (target exists but source globs no longer match) are detected and excluded from the registry with a warning.

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
