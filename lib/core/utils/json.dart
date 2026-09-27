Map<String, dynamic> jsonMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

Map<String, dynamic>? jsonMapOrNull(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

List<Map<String, dynamic>> jsonList(Object? value) => value is List
    ? [
        for (final item in value)
          if (item is Map) Map<String, dynamic>.from(item),
      ]
    : const [];

List<String> stringList(Object? value) =>
    value is List ? [for (final item in value) '$item'] : const [];

double? jsonDouble(Object? value) => value is num ? value.toDouble() : null;

int? jsonInt(Object? value) => value is num ? value.toInt() : null;
