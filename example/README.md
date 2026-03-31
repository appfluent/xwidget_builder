# Examples

Common usage examples for XWidget Builder commands.

## Project Setup

Initialize an existing Flutter project for XWidget:
```shell
dart run xwidget_builder:init
```

Scaffold a new XWidget app with working examples:
```shell
dart run xwidget_builder:init --new-app
```

## Code Generation

Generate all components:
```shell
dart run xwidget_builder:generate
```

Generate only inflaters:
```shell
dart run xwidget_builder:generate --only inflaters
```

## Cloud

Authenticate and deploy:
```shell
dart run xwidget_builder:xc cloud login
dart run xwidget_builder:xc cloud deploy -c staging -v 1.0.0
```

Promote a deployment from staging to production:
```shell
dart run xwidget_builder:xc cloud promote --from staging --to production -v 1.0.0
```

## Analytics

Query render and download analytics:
```shell
dart run xwidget_builder:xc analytics renders -c production -r 30
dart run xwidget_builder:xc analytics downloads -c production
```

## Help
```shell
dart run xwidget_builder:xc --help
dart run xwidget_builder:xc cloud --help
dart run xwidget_builder:xc analytics --help
```

For full documentation, visit [docs.xwidget.dev](https://docs.xwidget.dev).