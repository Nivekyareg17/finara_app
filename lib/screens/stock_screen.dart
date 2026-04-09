import 'package:flutter/material.dart';
import '../models/stock_model.dart';
import '../services/stock_service.dart';
import 'stock_detail_screen.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key});

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  final StockService service = StockService();

  late Future<List<Stock>> futureStocks;

  @override
  void initState() {
    super.initState();
    futureStocks = service.getStocks();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Market"),
      ),

      body: FutureBuilder<List<Stock>>(
        future: futureStocks,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stocks = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                futureStocks = service.getStocks();
              });
            },
            child: ListView.builder(
              itemCount: stocks.length,
              itemBuilder: (context, index) {
                final stock = stocks[index];
                final isUp = stock.change >= 0;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StockDetailScreen(stock: stock),
                      ),
                    );
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F2A25)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        // Nombre
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              stock.symbol,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "Stock",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),

                        // Precio
                        Text(
                          "\$${stock.price.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 16),
                        ),

                        // Cambio
                        Row(
                          children: [
                            Icon(
                              isUp
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color:
                                  isUp ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "${stock.percent.toStringAsFixed(2)}%",
                              style: TextStyle(
                                color: isUp
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}