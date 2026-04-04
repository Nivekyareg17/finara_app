class TransactionModel {
  int? id; // Opcional para que la base de datos lo autogenere
  String type; // "gasto" o "ingreso"
  double amount;
  String description;
  String category; // <--- NUEVO
  String date;     // <--- NUEVO
  String? imagePath; // <--- NUEVO (para el comprobante)

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    this.imagePath,
  });

  Map<String, dynamic> toMap() => {
        "id": id,
        "type": type,
        "amount": amount,
        "description": description,
        "category": category,
        "date": date,
        "imagePath": imagePath,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map["id"],
      type: map["type"],
      amount: (map["amount"] as num).toDouble(),
      description: map["description"],
      category: map["category"] ?? "General",
      date: map["date"] ?? "",
      imagePath: map["imagePath"],
    );
  }
}