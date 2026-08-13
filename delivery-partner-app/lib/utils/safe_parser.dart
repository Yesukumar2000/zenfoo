/// Safe type parser utility for parsing JSON values to desired types
/// Handles various input types and provides fallback values
class SafeParser {
  /// Safely parse to int from any type
  /// Handles: int, String, double, num, bool
  /// Returns: parsed int or defaultValue (defaults to 0)
  static int parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;

    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    if (value is bool) return value ? 1 : 0;

    return defaultValue;
  }

  /// Safely parse to double from any type
  /// Handles: double, int, String, num, bool
  /// Returns: parsed double or defaultValue (defaults to 0.0)
  static double parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;

    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    if (value is bool) return value ? 1.0 : 0.0;

    return defaultValue;
  }

  /// Safely parse to String from any type
  /// Handles: String, int, double, num, bool, null
  /// Returns: string representation or defaultValue (defaults to '')
  static String parseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;

    if (value is String) return value;
    return value.toString();
  }

  /// Safely parse to bool from any type
  /// Handles: bool, int, String ('true'/'1'), num
  /// Returns: parsed bool or defaultValue (defaults to false)
  static bool parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;

    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is num) return value.toInt() == 1;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1';
    }

    return defaultValue;
  }

  /// Safely parse to DateTime from any type
  /// Handles: DateTime, String (ISO8601), int/num (milliseconds since epoch)
  /// Returns: parsed DateTime or defaultValue (defaults to current time)
  static DateTime parseDateTime(dynamic value, {DateTime? defaultValue}) {
    final fallback = defaultValue ?? DateTime.now();

    if (value == null) return fallback;

    if (value is DateTime) return value;

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return fallback;
      }
    }

    if (value is int || value is num) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value is int ? value : value.toInt());
      } catch (e) {
        return fallback;
      }
    }

    return fallback;
  }

  /// Safely parse to List<T> from any type
  /// Handles: List, null
  /// Returns: casted list or empty list
  static List<T> parseList<T>(dynamic value, {List<T>? defaultValue}) {
    if (value == null) return defaultValue ?? <T>[];
    if (value is! List) return defaultValue ?? <T>[];

    try {
      return List<T>.from(value);
    } catch (e) {
      return defaultValue ?? <T>[];
    }
  }

  /// Safely parse to Map<String, dynamic> from any type
  /// Handles: Map, null
  /// Returns: casted map or empty map
  static Map<String, dynamic> parseMap(dynamic value, {Map<String, dynamic>? defaultValue}) {
    if (value == null) return defaultValue ?? <String, dynamic>{};
    if (value is! Map) return defaultValue ?? <String, dynamic>{};

    try {
      return Map<String, dynamic>.from(value);
    } catch (e) {
      return defaultValue ?? <String, dynamic>{};
    }
  }

  /// Parse nullable int
  /// Returns null if parsing fails or value is null
  static int? parseIntNullable(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    if (value is bool) return value ? 1 : 0;

    return null;
  }

  /// Parse nullable double
  /// Returns null if parsing fails or value is null
  static double? parseDoubleNullable(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is bool) return value ? 1.0 : 0.0;

    return null;
  }

  /// Parse nullable String
  /// Returns null if value is null or empty string
  static String? parseStringNullable(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      return value.isEmpty ? null : value;
    }

    final str = value.toString();
    return str.isEmpty ? null : str;
  }

  /// Parse nullable DateTime
  /// Returns null if parsing fails or value is null
  static DateTime? parseDateTimeNullable(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }

    if (value is int || value is num) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value is int ? value : value.toInt());
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Universal type converter - converts any value to desired type
  /// Supports: int, double, String, bool, DateTime, List, Map, and custom types
  /// Usage: SafeParser.parse<int>(value, defaultValue: 0)
  ///        SafeParser.parse<String>(value, defaultValue: '')
  ///        SafeParser.parse<MyClass>(value, parser: MyClass.fromJson)
  static T parse<T>(
    dynamic value, {
    T? defaultValue,
    T Function(Map<String, dynamic>)? parser,
  }) {
    try {
      // If value is null, return default
      if (value == null) {
        if (defaultValue != null) return defaultValue;
        throw Exception('Value is null and no defaultValue provided');
      }

      // If value is already the correct type, return it
      if (value is T) return value;

      final typeString = T.toString();

      // Handle String conversion first (before numeric conversions)
      if (typeString.contains('String')) {
        if (value is String) return value as T;
        return value.toString() as T;
      }

      // Handle int conversion
      if (typeString.contains('int')) {
        if (value is int) return value as T;
        if (value is num) return value.toInt() as T;
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed as T;
        }
        if (value is bool) return (value ? 1 : 0) as T;
        if (defaultValue != null) return defaultValue;
        return 0 as T;
      }

      // Handle double conversion
      if (typeString.contains('double')) {
        if (value is double) return value as T;
        if (value is num) return value.toDouble() as T;
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed as T;
        }
        if (value is bool) return (value ? 1.0 : 0.0) as T;
        if (defaultValue != null) return defaultValue;
        return 0.0 as T;
      }

      // Handle bool conversion
      if (typeString.contains('bool')) {
        if (value is bool) return value as T;
        if (value is int) return (value == 1) as T;
        if (value is num) return (value.toInt() == 1) as T;
        if (value is String) {
          final lower = value.toLowerCase().trim();
          return (lower == 'true' || lower == '1') as T;
        }
        if (defaultValue != null) return defaultValue;
        return false as T;
      }

      // Handle DateTime conversion
      if (typeString.contains('DateTime')) {
        if (value is DateTime) return value as T;
        if (value is String) {
          try {
            return DateTime.parse(value) as T;
          } catch (e) {
            // Try parsing as milliseconds
            final ms = int.tryParse(value);
            if (ms != null) {
              return DateTime.fromMillisecondsSinceEpoch(ms) as T;
            }
          }
        }
        if (value is int || value is num) {
          return DateTime.fromMillisecondsSinceEpoch(
            value is int ? value : value.toInt(),
          ) as T;
        }
        if (defaultValue != null) return defaultValue;
        return DateTime.now() as T;
      }

      // Handle List conversion
      if (typeString.startsWith('List')) {
        if (value is List) return value as T;
        if (defaultValue != null) return defaultValue;
        return [] as T;
      }

      // Handle Map conversion
      if (typeString.startsWith('Map')) {
        if (value is Map) return value as T;
        if (defaultValue != null) return defaultValue;
        return {} as T;
      }

      // Handle custom types with parser function
      if (parser != null && value is Map<String, dynamic>) {
        return parser(value) as T;
      }

      // If no conversion was possible, return default or throw
      if (defaultValue != null) return defaultValue;
      throw Exception('Cannot convert $value to type $T');
    } catch (e) {
      if (defaultValue != null) return defaultValue;
      rethrow;
    }
  }

  /// Parse value to type T with custom parser function
  /// Usage: SafeParser.parseCustom<MyClass>(jsonMap, MyClass.fromJson, defaultValue: MyClass())
  static T parseCustom<T>(
    dynamic value,
    T Function(Map<String, dynamic>) parser, {
    T? defaultValue,
  }) {
    try {
      if (value == null) {
        if (defaultValue != null) return defaultValue;
        throw Exception('Value is null');
      }

      if (value is T) return value;

      if (value is Map<String, dynamic>) {
        return parser(value);
      }

      if (defaultValue != null) return defaultValue;
      throw Exception('Cannot parse $value with provided parser');
    } catch (e) {
      if (defaultValue != null) return defaultValue;
      rethrow;
    }
  }

  /// Convert value using type conversion map
  /// Useful for converting fields in bulk
  /// Usage:
  /// final converted = SafeParser.parseWithMap(data, {
  ///   'age': (v) => SafeParser.parse<int>(v, defaultValue: 0),
  ///   'name': (v) => SafeParser.parse<String>(v, defaultValue: ''),
  ///   'isActive': (v) => SafeParser.parse<bool>(v, defaultValue: false),
  /// });
  static Map<String, dynamic> parseWithMap(
    Map<String, dynamic> data,
    Map<String, dynamic Function(dynamic)> converters,
  ) {
    final result = <String, dynamic>{};

    for (final entry in converters.entries) {
      final key = entry.key;
      final converter = entry.value;

      try {
        result[key] = converter(data[key]);
      } catch (e) {
        result[key] = null;
      }
    }

    return result;
  }
}
