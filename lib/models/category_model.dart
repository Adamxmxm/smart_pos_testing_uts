class CategoryModel {
  final String id;
  final String name;
  final DateTime? createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final data = <String, dynamic>{
      'name': name,
    };
    if (includeId) {
      data['id'] = id;
    }
    return data;
  }
}
