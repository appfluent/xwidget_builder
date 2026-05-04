<p align="center">
    <img src="https://raw.githubusercontent.com/appfluent/xwidget_builder/main/doc/assets/xwidget_builder_logo_full.png"
        alt="XWidget Builder Logo"
        height="80"
    />
</p>

# XWidget Builder

XWidget Builder is the development toolchain for
[XWidget](https://pub.dev/packages/xwidget). It generates the Dart registration
code and XML schema an XWidget app needs, and it provides the CLI for project
setup, XWidget Cloud deployments, and analytics.

Use it as a dev dependency in Flutter apps that render XWidget XML fragments.

## What It Generates

| Output | Purpose |
|--------|---------|
| Inflaters | Runtime adapters that create Flutter widgets from XML elements |
| Icons | Icon registrations for XML icon references |
| Controllers | Controller factories for XML `<Controller>` elements |
| Registry | A single `registerXWidgetComponents()` entry point for `XWidget.initialize()` |
| Schema | `xwidget_schema.g.xsd` for XML validation, completion, and IDE tooltips |

## Quick Start

Add XWidget and XWidget Builder to a Flutter project:

```bash
flutter pub add xwidget dev:xwidget_builder
```

Initialize XWidget project files:

```bash
dart run xwidget_builder:init
```

Generate components:

```bash
dart run xwidget_builder:generate
```

Then register the generated code in your app:

```dart
import 'package:flutter/material.dart';
import 'package:xwidget/xwidget.dart';

import 'xwidget/generated/registry.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await XWidget.initialize(register: registerXWidgetComponents);

  runApp(const MyApp());
}
```

For a new example app, run:

```bash
dart run xwidget_builder:init --new-app
dart run xwidget_builder:generate
```

## CLI

The package exposes three entry points:

```bash
dart run xwidget_builder:init
dart run xwidget_builder:generate
dart run xwidget_builder:xc --help
```

You can also install the optional `xc` shortcut for shorter commands:

```bash
xc init
xc generate
xc cloud login
xc analytics renders
```

## Features

- **Code generation** - Generate type-safe inflaters, icon registrations,
  controller factories, a registry, and an XML schema from Dart specs.
- **Project scaffolding** - Bootstrap an existing Flutter app or replace a new
  project with a working XWidget example app.
- **Schema and IDE support** - Generate XML validation, completion, and hover
  documentation for XWidget fragments.
- **Cloud deployment** - Deploy UI bundles to XWidget Cloud for over-the-air
  updates without app store review.
- **Analytics CLI** - Query render, download, error, and navigation analytics
  from the command line.

## Documentation

Full documentation is available at **[docs.xwidget.dev](https://docs.xwidget.dev)**,
including:

- [Quick Start](https://docs.xwidget.dev/getting_started/quick_start/) - installation and setup
- [Code Generation](https://docs.xwidget.dev/builder/overview/) - inflaters, icons,
  controllers, registry, and schema
- [Configuration](https://docs.xwidget.dev/builder/configuration/) - `xwidget_config.yaml` reference
- [Registry](https://docs.xwidget.dev/builder/registry/) - generated component registration
- [Schema](https://docs.xwidget.dev/builder/schema/) - XML validation and IDE integration
- [CLI Setup](https://docs.xwidget.dev/builder/cli_setup/) - optional `xc` command setup
- [Cloud](https://docs.xwidget.dev/cloud/overview/) - workspaces, projects, channels,
  and deployments
- [Analytics](https://docs.xwidget.dev/analytics/overview/) - downloads, renders, errors,
  and transitions

## IDE Plugins

- [Flutter XWidget for Android Studio / IntelliJ](https://plugins.jetbrains.com/plugin/25494-flutter-xwidget)
- [Flutter XWidget for VS Code](https://marketplace.visualstudio.com/items?itemName=appfluent.flutter-xwidget)

The plugins use the generated schema and XWidget project structure to provide
EL syntax highlighting, contextual navigation, component generation, and hot
reload for fragments and resource values.

## License

See [LICENSE](LICENSE) for details.
