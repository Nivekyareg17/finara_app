import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock_model.dart';

class StockService {
  final String baseUrl = "https://finara-api-1lmd.onrender.com/api/stocks/";

  Future<List<Stock>> getStocks() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Stock.fromJson(e)).toList();
    } else {
      throw Exception("Error al cargar acciones");
    }
  }

  Future<List<double>> getHistory(String symbol, String range) async {
    final response = await http.get(
      Uri.parse(
          "https://finara-api-1lmd.onrender.com/api/stocks/history?symbol=$symbol&range=$range"),
    );

    final data = json.decode(response.body);

    return List<double>.from(
      data["prices"].map((e) => (e as num).toDouble()),
    );
  }
}
