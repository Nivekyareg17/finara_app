class TransactionModel {
  int? id;
  String type;
  double amount;
  String description;

  String categoryId;
  String categoryName;

  String date;
  String? imagePath;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    this.imagePath,
  });

  Map<String, dynamic> toMap() => {
        "id": id,
        "type": type,
        "amount": amount,
        "description": description,
        "categoryId": categoryId,
        "categoryName": categoryName,
        "date": date,
        "imagePath": imagePath,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map["id"],
      type: map["type"],
      amount: (map["amount"] as num).toDouble(),
      description: map["description"],
      categoryId: (map["category_id"] ?? map["categoryId"])?.toString() ?? "0",
      categoryName: map["category_name"] ??
          map["categoryName"] ??
          map["category"] ??
          "General",
      date: map["date"] ?? "",
      imagePath: map["imagePath"],
    );
  }
}
