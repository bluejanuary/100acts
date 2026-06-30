class ActSummary {
  final String id;
  final double lat;
  final double long;
  final String category;

  ActSummary({
    required this.id,
    required this.lat,
    required this.long,
    required this.category,
  });

  factory ActSummary.fromJson(Map<String, dynamic> json) {
    return ActSummary(
      id: (json['id'] ?? '') as String,
      lat: (json['lat'] as num).toDouble(),
      long: (json['long'] as num).toDouble(),
      category: (json['category'] ?? '') as String,
    );
  }
}
