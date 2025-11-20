<!-- This file was generated. Run 'dart run tool/markdown.dart -i doc/README.md -o README.md' to update this file. -->

<!-- README.md template -->

<!-- #include HEADER.md -->
<p align="center">
    <img src="https://raw.githubusercontent.com/appfluent/xwidget_builder/main/doc/assets/xwidget_builder_logo_full.png"
        alt="XWidget Logo"
        height="100"
    />
</p>

### *Note: This document is very much still a work in progress.*
<!-- // end of #include -->

<!-- #include INTRO.md -->
# What is XWidget Builder?

XWidget Builder is a command-line tool for generating [XWidget]() inflaters, controllers, 
icons, and schema files. Additionally, it includes a tool for bootstrapping a new XWidget 
project, streamlining the setup process.

**Important:** Only specify widgets that you actually use in your UI. Specifying unused widgets and
helper classes in your configuration will bloat your app size. This is because code is generated for
every component you specify and thus neutralizes Flutter's tree-shaking.
<!-- // end of #include -->

<!-- #include CONFIGURATION.md -->
# Configuration

By default, the builder searches for a custom configuration file named `xwidget_config.yaml` in
the project root. This configuration extends XWidget’s default settings, reducing the
amount of manual setup. For reference, see `package:xwidget/res/default_config.yaml`, which defines
the built-in defaults.

Since the default config does most of the heavy lifting, the typical config can be relatively simple
like this example:

```yaml
# custom config - xwidget_config.yaml
inflaters:
  imports: [
    "dart:ui",
    "package:flutter/foundation.dart",
    "package:flutter/gestures.dart",
  ]
  sources: [ "lib/xwidget/inflater_spec.dart" ]
  includes: [ "lib/xwidget/inflater_spec_includes.dart" ]

icons:
  sources: [ "lib/xwidget/icon_spec.dart" ]
```

There are four top-level mappings that configure each of the four generated
outputs: `inflaters`, `schema`, `controllers`, and `icons`.

### Inflaters Configuration

```yaml
# Responsible for configuring inputs and outputs to generate inflaters.
inflaters:

  # The file path to save the generated code. The output contains all inflater classes
  # and a library function to to register them. The default value can be overwritten.
  # 
  # DEFAULT: "lib/xwidget/generated/inflaters.g.dart"
  target:

  # A list of additional imports to include in the generated output. Sometimes the code
  # generator can't determine all the required imports. This happens because of a
  # current limitation in dealing with default values for constructor arguments. This
  # option allows manual configuration when needed. Custom imports are appended to
  # XWidget's default list.
  #
  # DEFAULT: [ "package:xwidget/xwidget.dart" ]
  imports: [ ]

  # List of list inflater specification source files. Specifications tell XWidget which 
  # objects to create inflaters for.
  #
  # DEFAULT: none
  sources: [ ]

  # DEFAULT none
  includes: [ ]

  # DEFAULT: See 'package:xwidget/res/default_config.yaml'
  constructor_exclusions: [ "<class_name | * for any>:<constructor_argument_name>", ]

  # DEFAULT: See 'package:xwidget/res/default_config.yaml'
  constructor_arg_defaults:
    "<class_name | * for any>:<constructor_argument_name>": "<value>"

  # DEFAULT: See 'package:xwidget/res/default_config.yaml'
  constructor_arg_parsers:

    # EXAMPLES:
    # - "double": "double.parse(value)"
    # - "Alignment": "parseAlignment(value)"
    # - "*:width": "parseWidth(value)"
    "<constructor_argument_type | * for any>(: <constructor_argument_name>)": "<parser_function_call>"
```

```dart
// example inflater specification.
import 'package:flutter/material.dart';

// Best Practice: Keep declarations in alphabetical order. It makes it much easier
// to quickly determine what has been added and what is missing.

const inflaters = [
  AppBar,
  Center,
  Column,
  FloatingActionButton,
  Icon,
  MaterialApp,
  Scaffold,
  Text,
  TextStyle,
  ThemeData,
];
```

### Schema Configuration

```yaml
# Responsible for configuring inputs and outputs to generate the inflater schema.
# Register the generated schema with your IDE to get code completion and documentation
# while editing fragments. 
schema:

  # DEFAULT: "xwidget_schema.g.xsd"
  target:

  # DEFAULT: "xwidget|res/schema_template.xsd"   
  template:

  # DEFAULT: See 'package:xwidget/res/default_config.yaml'
  types:
    # EXAMPLES
    # - "bool": "boolAttributeType"
    # - "BoxFit": "BoxFitAttributeType"
    "<constructor_argument_type>": "<schema_defined_type>"

  # DEFAULT: See 'package:xwidget/res/default_config.yaml'
  attribute_exclusions: [

    # EXAMPLES:
    # - "*:child"                       
    "<class_name | * for any>:<constructor_argument_name | * for any>",
  ]
```

### Controllers Configuration

```yaml
controllers:

  # DEFAULT: "lib/xwidget/generated/controllers.g.dart" 
  target:

  # DEFAULT: [ "package:xwidget/xwidget.dart" ]
  imports: [ ]

  # DEFAULT: [ "lib/xwidget/controllers/**.dart" ]
  sources: [ ]
```

### Icons Configuration

```yaml
icons:

  # DEFAULT: "lib/xwidget/generated/icons.g.dart"
  target:

  # DEFAULT: [ "package:xwidget/xwidget.dart" ]
  imports: [ ]

  # List of list icon specification source files. Specifications tell XWidget
  # which icons to register.
  #
  # DEFAULT: none
  sources: [ ]
```

```dart
// example icon specification
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// List icons individually to reduce app size.
const icons = [
  Icons.add,
  Icons.delete,
];

// Not recommended, but you can also include the entire icon set by simply
// referencing the enclosing class. This assumes that each icon is declared
// as a static field of type IconData.
const iconSets = [
  CupertinoIcons,
];
```
<!-- // end of #include -->

<!-- #include CODE_GENERATION.md -->
# Code Generation

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
<!-- // end of #include -->