class CacheEnvelope {
  const CacheEnvelope({required this.savedAt, required this.payload});

  final DateTime savedAt;

  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'saved_at': savedAt.toIso8601String(),
        'payload': payload,
      };

  factory CacheEnvelope.fromJson(Map<String, dynamic> json) => CacheEnvelope(
        savedAt: DateTime.parse(json['saved_at'] as String),
        payload: json['payload'] as Map<String, dynamic>,
      );
}
