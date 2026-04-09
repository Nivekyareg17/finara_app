import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/stock_model.dart';
import '../services/stock_service.dart';

class StockDetailScreen extends StatefulWidget {
  final Stock stock;

  const StockDetailScreen({super.key, required this.stock});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  String selectedRange = "1W";

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
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
            // 🔹 Precio
            Text(
              "\$${stock.price.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // 🔹 Cambio
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

            const SizedBox(height: 20),

            // 🔹 BOTONES DE RANGO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ["1D", "1W", "1M"].map((range) {
                final isSelected = selectedRange == range;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedRange = range;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      range,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 🔹 GRÁFICA
            FutureBuilder<List<double>>(
              future: StockService()
                  .getHistory(stock.symbol, selectedRange),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final prices = snapshot.data!;

                return SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: prices.asMap().entries.map((e) {
                            return FlSpot(
                              e.key.toDouble(),
                              e.value,
                            );
                          }).toList(),
                          isCurved: true,
                          dotData: FlDotData(show: false),
                          color: isUp ? Colors.green : Colors.red,
                          barWidth: 3,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // 🔹 INFO EXTRA
            const Text(
              "Información",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text("Símbolo: ${stock.symbol}"),
            Text("Cambio: ${stock.change.toStringAsFixed(2)}"),
            Text("Porcentaje: ${stock.percent.toStringAsFixed(2)}%"),
          ],
        ),
      ),
    );
  }
}