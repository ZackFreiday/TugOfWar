class Category {
  final int id;
  final String name;
  final String slug;
  final int displayOrder;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.displayOrder,
    required this.isActive,
  });

  factory Category.fromJson(
    Map<String, dynamic> json,
  ) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      displayOrder:
          json['displayOrder'] as int? ?? 0,
      isActive:
          json['isActive'] as bool? ?? true,
    );
  }
}