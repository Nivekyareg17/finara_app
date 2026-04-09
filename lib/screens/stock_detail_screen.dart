import 'package:flutter/material.dart';
import '../models/stock_model.dart';

class StockDetailScreen extends StatelessWidget {
  final Stock stock;

  const StockDetailScreen({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final isUp = stock.change >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(stock.symbol),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Precio
            Text(
              "\$${stock.price.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Cambio
            Row(
              children: [
                Icon(
                  isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isUp ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 5),
                Text(
                  "${stock.percent.toStringAsFixed(2)}%",
                  style: TextStyle(
                    color: isUp ? Colors.green : Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // "Gráfica" simulada (luego la hacemos real)
            SizedBox(
              height: 250,
              child: Center(
                child: Text("Aquí irá la gráfica real 📊"),
              ),
            ),

            const SizedBox(height: 30),

            // Info extra
            Text(
              "Información",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text("Símbolo: ${stock.symbol}"),
            Text("Cambio: ${stock.change.toStringAsFixed(2)}"),
          ],
        ),
      ),
    );
  }
}
