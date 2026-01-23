import 'package:analyzer/dart/element/type.dart';

extension StringExt on String {
  String removeTrailingString(String remove) {
    return endsWith(remove) ? substring(0, length - remove.length) : this;
  }

  String capitalizeFirst() {
    return isNotEmpty
        ? substring(0,1).toUpperCase() + substring(1, length)
        : this;
  }
}
extension TypeExt on Type {
  String getBaseTypeName() {
    final fullName = toString();
    final genericStart = fullName.indexOf('<');
    if (genericStart == -1) {
      return fullName; // No type parameters
    }
    return fullName.substring(0, genericStart);
  }
}

extension DartTypeExt on DartType {
  String displayStringWithoutNullability() {
    final str = getDisplayString();
    return str.endsWith("?") || str.endsWith("*")
        ? str.substring(0, str.length - 1)
        : str;
  }

  Type? coreType() {
    if (isDartCoreBool) return bool;
    if (isDartCoreDouble) return double;
    if (isDartCoreEnum) return Enum;
    if (isDartCoreFunction) return Function;
    if (isDartCoreInt) return int;
    if (isDartCoreIterable) return Iterable;
    if (isDartCoreList) return List;
    if (isDartCoreMap) return Map;
    if (isDartCoreNull) return Null;
    if (isDartCoreNum) return num;
    if (isDartCoreObject) return Object;
    if (isDartCoreRecord) return Record;
    if (isDartCoreSet) return Set;
    if (isDartCoreString) return String;
    if (isDartCoreSymbol) return Symbol;
    if (isDartCoreType) return Type;
    return null;
  }
}
