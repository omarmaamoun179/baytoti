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

String? jsonId(Object? value) => switch (value) {
      final String id when id.isNotEmpty => id,
      final num id => '${id is int ? id : id.toInt()}',
      final Map<dynamic, dynamic> object => jsonId(object['id']),
      _ => null,
    };

String? jsonString(Object? value) => switch (value) {
      final String text => text,
      final num number => '$number',
      _ => null,
    };

bool? jsonBool(Object? value) => switch (value) {
      final bool flag => flag,
      final num flag => flag != 0,
      final String flag when flag == '1' || flag.toLowerCase() == 'true' =>
        true,
      final String flag when flag == '0' || flag.toLowerCase() == 'false' =>
        false,
      _ => null,
    };

int? jsonCount(Object? value) => switch (value) {
      final num number => number.toInt(),
      final String text => int.tryParse(text),
      _ => null,
    };
