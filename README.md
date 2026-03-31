<p align="center">
    <img src="https://raw.githubusercontent.com/appfluent/xwidget_builder/main/doc/assets/xwidget_builder_logo_full.png"
        alt="XWidget Builder Logo"
        height="80"
    />
</p>

# XWidget Builder

A command-line tool and code generator for [XWidget](https://pub.dev/packages/xwidget) projects. It generates the inflaters, controllers, icons, and XML schema files that XWidget needs to render your UI from XML fragments at runtime — plus a full CLI for deploying to XWidget Cloud and querying analytics.

## Features

- **Code Generation** — Auto-generate type-safe inflaters, icon registrations, controller factories, and XSD schema from simple Dart specs
- **Project Scaffolding** — Bootstrap a new XWidget project with a single command
- **Cloud Deployment** — Deploy UI bundles to XWidget Cloud for over-the-air updates without app store review
- **Analytics** — Query render, download, error, and navigation analytics from the command line
- **IDE Integration** — Generated XML schema provides code completion, validation, and documentation tooltips

## Quick Start

1. **Install:**
```bash
    flutter pub add xwidget dev:xwidget_builder
```

2. **Initialize your project:**
```bash
    dart run xwidget_builder:init --new-app
```

3. **Generate components:**
```bash
    dart run xwidget_builder:generate
```

4. **Deploy to the cloud (optional):**
```bash
    dart run xwidget_builder:xc cloud login
    dart run xwidget_builder:xc cloud deploy -c production -v 1.0.0
```

## Documentation

Full documentation is available at **[docs.xwidget.dev](https://docs.xwidget.dev)**, including:

- [Code Generation](https://docs.xwidget.dev/builder/overview/) — Inflaters, icons, controllers, schema
- [Configuration](https://docs.xwidget.dev/builder/configuration/) — xwidget_config.yaml reference
- [Cloud](https://docs.xwidget.dev/cloud/overview/) — Workspaces, projects, channels, deployments
- [Analytics](https://docs.xwidget.dev/analytics/overview/) — Downloads, renders, errors, transitions
- [CLI Reference](https://docs.xwidget.dev/builder/cli/) — All available commands

## Android Studio Plugin

Install the [Flutter XWidget](https://plugins.jetbrains.com/plugin/25494-flutter-xwidget) plugin for EL syntax highlighting, contextual navigation, and component generation.

## License

See [LICENSE](LICENSE) for details.