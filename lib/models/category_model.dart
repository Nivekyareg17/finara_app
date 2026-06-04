class CategoryModel {
  final String id;
  final String name;
  final String type;
  final String currency;
  final String icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.currency = "COP",
    this.icon = "category",
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'].toString(),
      name: map['name'],
      type: map['type'],
      currency:
          (map['currency'] ?? map['currency_code'] ?? map['moneda'] ?? "COP")
              .toString()
              .toUpperCase(),
      icon: (map['icon'] ?? "category").toString(),
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? type,
    String? currency,
    String? icon,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "type": type,
      "currency": currency,
      "icon": icon,
    };
  }
}
