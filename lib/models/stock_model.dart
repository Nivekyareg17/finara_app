class Stock {
  final String symbol;
  final double price;
  final double change;
  final double percent;

  Stock({
    required this.symbol,
    required this.price,
    required this.change,
    required this.percent,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'],
      price: (json['price'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      percent: (json['percent'] ?? 0).toDouble(),
    );
  }
}