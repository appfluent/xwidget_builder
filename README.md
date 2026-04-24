<p align="center">
    <img src="https://raw.githubusercontent.com/appfluent/xwidget_builder/main/doc/assets/xwidget_builder_logo_full.png"
        alt="XWidget Builder Logo"
        height="80"
    />
</p>

# XWidget Builder

A command-line tool and code generator for [XWidget](https://pub.dev/packages/xwidget) projects. It generates the inflaters,
controllers, icons, and XML schema files that XWidget needs to render your UI from XML fragments
at runtime — plus a full CLI for deploying to XWidget Cloud and querying analytics.

## Features

- **Code Generation** — Auto-generate type-safe inflaters, icon registrations, controller factories, and XSD schema from simple Dart specs
- **Project Scaffolding** — Bootstrap a new XWidget project with a single command
- **Cloud Deployment** — Deploy UI bundles to XWidget Cloud for over-the-air updates without app store review
- **Analytics** — Query render, download, error, and navigation analytics from the command line
- **IDE Integration** — Generated XML schema provides code completion, validation, and documentation tooltips

## Documentation

Full documentation is available at **[docs.xwidget.dev](https://docs.xwidget.dev)**, including:

- [Getting Started](https://docs.xwidget.dev/getting_started/introduction/) — Installation, project setup, first fragment
- [Code Generation](https://docs.xwidget.dev/builder/overview/) — Inflaters, icons, controllers, schema
- [Configuration](https://docs.xwidget.dev/builder/configuration/) — xwidget_config.yaml reference
- [Cloud](https://docs.xwidget.dev/cloud/overview/) — Workspaces, projects, channels, deployments
- [Analytics](https://docs.xwidget.dev/analytics/overview/) — Downloads, renders, errors, transitions
- [CLI Reference](https://docs.xwidget.dev/builder/cli/) — All available commands

## IDE Plugins

- **[Flutter XWidget for Android Studio / IntelliJ](https://plugins.jetbrains.com/plugin/25494-flutter-xwidget)** — EL syntax highlighting, contextual navigation, component generation, and hot reload of fragments and resource values.
- **[Flutter XWidget for VSCode](https://marketplace.visualstudio.com/items?itemName=appfluent.flutter-xwidget)** — Same feature set for VSCode users.

## License

See [LICENSE](LICENSE) for details.