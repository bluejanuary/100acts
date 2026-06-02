class Act {
  final String id;
  final String category;
  final String description;
  final String photoUrl;
  final List<String> photoUrls;
  final double lat;
  final double long;
  final DateTime createdAt;

  Act({
    required this.id,
    required this.category,
    required this.description,
    required this.photoUrl,
    required this.photoUrls,
    required this.lat,
    required this.long,
    required this.createdAt,
  });

  factory Act.fromJson(Map<String, dynamic> json) {
    final photoUrl = (json['photoUrl'] ?? json['photo_url'] ?? '') as String;
    final rawUrls = json['photoUrls'] ?? json['photo_urls'];
    final photoUrls = rawUrls != null
        ? List<String>.from(rawUrls as List)
        : photoUrl.isNotEmpty ? [photoUrl] : <String>[];
    return Act(
      id: json['id'] as String,
      category: json['category'] as String,
      description: (json['description'] ?? '') as String,
      photoUrl: photoUrl,
      photoUrls: photoUrls,
      lat: (json['lat'] as num).toDouble(),
      long: (json['long'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
