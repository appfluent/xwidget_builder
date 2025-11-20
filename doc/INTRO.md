# What is XWidget Builder?

XWidget Builder is a command-line tool for generating [XWidget]() inflaters, controllers, 
icons, and schema files. Additionally, it includes a tool for bootstrapping a new XWidget 
project, streamlining the setup process.

**Important:** Only specify widgets that you actually use in your UI. Specifying unused widgets and
helper classes in your configuration will bloat your app size. This is because code is generated for
every component you specify and thus neutralizes Flutter's tree-shaking.