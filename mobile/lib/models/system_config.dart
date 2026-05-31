class CategoryConfig {
  final String id;
  final String name;
  final String slug;

  CategoryConfig({required this.id, required this.name, required this.slug});

  factory CategoryConfig.fromJson(Map<String, dynamic> json) =>
      CategoryConfig(id: json['id'], name: json['name'], slug: json['slug']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug};
}

class SystemConfig {
  final List<CategoryConfig> categories;

  SystemConfig({required this.categories});

  factory SystemConfig.fromJson(Map<String, dynamic> json) => SystemConfig(
        categories: (json['categories'] as List)
            .map((c) => CategoryConfig.fromJson(c))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'categories': categories.map((c) => c.toJson()).toList(),
      };
}
