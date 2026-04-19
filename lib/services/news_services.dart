import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsArticle {
  final String titulo;
  final String categoria;
  final String imagen;
  final String fecha;
  final String url;

  NewsArticle({
    required this.titulo,
    required this.categoria,
    required this.imagen,
    required this.fecha,
    required this.url,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      titulo: json['titulo'] ?? '',
      categoria: json['categoria'] ?? '',
      imagen: json['imagen'] ?? '',
      fecha: json['fecha'].toString(),
      url: json['url'] ?? '',
    );
  }
}

class NewsService {
  final String baseUrl = "https://finara-api-1lmd.onrender.com/api/news";

  Future<List<NewsArticle>> getNews() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => NewsArticle.fromJson(e)).toList();
    } else {
      throw Exception("Error al cargar noticias");
    }
  }
}
