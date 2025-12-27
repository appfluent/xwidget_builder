# App Initialization

The easies way to get stated is by letting XWidget initialize your project for you.

Installs XWidget dependencies and installs required configuration files, but does not overwrite
existing files.
```shell
$ dart run xwidget_builder:init
```

Installs XWidget dependencies and installs a basic example app, overwriting existing files.
```shell
$ dart run xwidget_builder:int --new-app
```

Displays usage help
```shell
$ dart run xwidget_builder:generate --help
```

# Code Generation

Once you've initialized you app, use the following commands to generate XWidget components

To generate inflaters, controllers, and other required files, run the following command:
```shell
$ dart run xwidget_builder:generate
```

To see available options and flags, use:
```shell
$ dart run xwidget_builder:generate --help
```

You can also specify a custom configuration file:
```shell
$ dart run xwidget_builder:generate --config "my_config.yaml"
```

To generate only specific components, use the --only flag:
```shell
$ dart run xwidget_builder:generate --only inflaters,controllers,icons
```

If you need to support deprecated APIs, use:
```shell
$ dart run xwidget_builder:generate --allow-deprecated
```

The generated files will be placed in the appropriate directories as specified
in xwidget_config.yaml.