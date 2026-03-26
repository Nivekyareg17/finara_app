class TransactionModel {
  int id;
  String type;
  double amount;
  String description;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
        "id": id,
        "type": type,
        "amount": amount,
        "description": description,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map["id"],
      type: map["type"],
      amount: (map["amount"] as num).toDouble(),
      description: map["description"],
    );
  }
}
