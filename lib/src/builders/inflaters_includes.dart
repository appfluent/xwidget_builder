part of 'inflaters.dart';

String _buildInflaterAddIns() {
  return '''
class InflaterArgs {
  final Map<String, dynamic> attributes;
  final List<dynamic> children;
  final List<String> text;

  final posArgs = <dynamic>[];
  final namedArgs = <Symbol, dynamic>{};

  int pos = 0;

  InflaterArgs(this.attributes, this.children, this.text);

  void addMapArg<K,V>(
      String name,
      bool isRequired,
      bool isPositional,
      dynamic defaultValue,
  ) {
    final isPresent = _isPresent(name, defaultValue);
    if (isRequired && !isPresent) {
      throw Exception("Argument '\$name' of type 'Map<\$K,\$V>' is required");
    }
    if (isPresent) {
      final arg = _getArgValue(name, defaultValue);
      if (arg is Map) {
        _addArg(name, <K,V>{...arg}, isPositional);
      } else if (arg == null) {
        _addArg(name, null, isPositional);
      } else {
        throw Exception("Argument '\$name' of type '\${arg.runtimeType}' is "
            "not a subtype of Map<\$K,\$V>");
      }
    }
  }

  void addArg<T>(
      String name,
      Type? coreType,
      bool isRequired,
      bool isPositional,
      dynamic defaultValue,
  ) {
    final isPresent = _isPresent(name, defaultValue);
    if (isRequired && !isPresent) {
      throw Exception("Argument '\$name' of type '\$T' is required");
    }
    if (isPresent) {
      final arg = _getArgValue(name, defaultValue);
      if (coreType == List || coreType == Iterable) {
        _addArg(name, arg is List ? <T>[...arg] : null, isPositional);
      } else if (coreType == Set) {
        _addArg(name, arg is Set ? <T>{...arg} : null, isPositional);
      } else if (coreType == String) {
        _addArg(name, arg?.toString(), isPositional);
      } else if (coreType == double) {
        _addArg(name, toDouble(arg), isPositional);
      } else {
        _addArg(name, arg, isPositional);
      }
    }
  }

  bool _isPresent(String name, dynamic defaultValue) {
    // check for a key instead of a null value, because the user may have
    // intentionally set the value to null which means it should be passed
    // as the arg.
    return attributes.containsKey(name) || defaultValue != null ||
        ((name == "children" || name == "child") && children.isNotEmpty);
  }
  
  void _addArg(String name, dynamic value, bool isPositional) {
    if (isPositional) {
      posArgs.insertFill(pos++, value, null);
    } else {
      namedArgs[Symbol(name)] = value;
    }
  }

  dynamic _getArgValue(String name, dynamic defaultValue) {
    if (name == "children") {
      return children.isEmpty ? attributes['children'] ?? defaultValue : children;
    } else if (name == "child") {
      return children.isEmpty ? attributes['child'] ?? defaultValue : children[0];
    } else {
      return attributes[name] ?? defaultValue;
    }
  }
}\n
''';
}
