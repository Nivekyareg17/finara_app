import 'package:flutter/material.dart';
import '../services/stock_service.dart';
import '../models/stock_model.dart';

class StocksScreen extends StatefulWidget {
  @override
  _StocksScreenState createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  final StockService service = StockService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bolsa de Valores")),
      body: FutureBuilder<List<Stock>>(
        future: service.getStocks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final stocks = snapshot.data!;

          return ListView.builder(
            itemCount: stocks.length,
            itemBuilder: (context, index) {
              final stock = stocks[index];

              return ListTile(
                title: Text(stock.symbol),
                subtitle: Text("Precio: ${stock.price.toStringAsFixed(2)}"),
                trailing: Text(
                  "${stock.percent.toStringAsFixed(2)}%",
                  style: TextStyle(
                    color: stock.change >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}