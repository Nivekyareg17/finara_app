class CategoryModel {
  final String id;
  final String name;
  final String type;

    CategoryModel({
    required this.id,
    required this.name,
    required this.type,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'].toString(),
      name: map['name'],
      type: map['type'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "type": type,
    };
  }
}
