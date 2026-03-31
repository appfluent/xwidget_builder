## 0.3.0 (Mar 31, 2026)

### Added
- Cloud management CLI — deploy, promote, and manage workspaces, projects, channels, and deployments via `xc cloud`.
- Analytics CLI — query render, download, error, and page transition data via `xc analytics`.
- Project key rotation with configurable grace periods (0–90 days).
- `xc` top-level CLI entry point for all XWidget Builder commands.
- Full documentation site at docs.xwidget.dev.

### Changed
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
