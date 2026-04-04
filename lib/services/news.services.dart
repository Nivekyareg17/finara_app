import 'dart:async';

// Modelo de datos rápido para las noticias
class NewsArticle {
  final String title;
  final String category;
  final String imageUrl;
  final String date;

  NewsArticle({
    required this.title, 
    required this.category, 
    required this.imageUrl, 
    required this.date
  });
}

class NewsService {
  // Esta función simula una llamada a internet
  Future<List<NewsArticle>> getFakeNews() async {
    await Future.delayed(const Duration(seconds: 1)); // Simula carga de 1 seg

    return [
      NewsArticle(
        title: "Bitcoin se mantiene estable tras el cierre semanal",
        category: "MERCADO",
        imageUrl: "https://picsum.photos/seed/btc/400/200",
        date: "Hoy",
      ),
      NewsArticle(
        title: "5 consejos para mejorar tu ahorro mensual",
        category: "FINANZAS",
        imageUrl: "https://picsum.photos/seed/save/400/200",
        date: "Ayer",
      ),
      NewsArticle(
        title: "Nueva actualización en la red de Ethereum",
        category: "CRIPTOS",
        imageUrl: "https://picsum.photos/seed/eth/400/200",
        date: "2 días",
      ),
    ];
  }
}