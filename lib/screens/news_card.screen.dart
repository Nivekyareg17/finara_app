import 'package:finara_app_v1/services/news_services.dart';
import 'package:flutter/material.dart';
import '../../models/news_model.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:finara_app_v1/services/translation_service.dart'; 
import '../widgets/translate_widget.dart';
import '../widgets/app_drawer.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  Future<void> _abrirNoticia(String url) async {
    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'No se pudo abrir la noticia';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark; 
    // Datos de ejemplo que vendrían de tu API
    final newsService = NewsService();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Color(0xFF00C853),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.account_balance_rounded,
                  color: Colors.white, size: 18),
            ),
            SizedBox(width: 8),
            TranslatedText(
              "Finara News",
              style: TextStyle(
                  color:Color.fromARGB(255, 10, 109, 82),
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildStockTicker(),
          Expanded(
            child: FutureBuilder<List<NewsArticle>>(
              future: newsService.getNews(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error al cargar noticias"));
                } else {
                  final noticias = snapshot.data!;

                  return ListView.separated(
                    padding: EdgeInsets.all(16.0),
                    itemCount: noticias.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final noticia = noticias[index];

                      return GestureDetector(
                          onTap: () => _abrirNoticia(noticia.url),
                          child: _buildNewsCard(
                            NoticiaAPI(
                              categoria: noticia.categoria.toUpperCase(),
                              tiempoHace: "Reciente",
                              titulo: noticia.titulo,
                              tiempoLectura: "3 min",
                              imagen: noticia.imagen,
                              url: noticia.url,
                            ),
                            isDark,
                          ));
                    },
                  );
                }
              },
            ),
          )
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(
        selectedIndex: 1, //NEWS
      ),
    );
  }

  //WIDGETS DE APOYO

  // 1. Build de lista de news (Ticker)
  Widget _buildStockTicker() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    );
  }



  // 3. Tarjeta de Noticia Principal
  Widget _buildNewsCard(NoticiaAPI noticia, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
    ? const Color.fromARGB(255, 32, 32, 32)
    : Color.fromARGB(255, 128, 127, 127),
    borderRadius: BorderRadius.circular(16),
    ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de Marcador de Posición (API Placeholder)
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              image: DecorationImage(
                image: noticia.imagen.isNotEmpty
                    ? NetworkImage(noticia.imagen)
                    : NetworkImage("https://via.placeholder.com/400"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Contenido de Texto
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(width: 8),
                    TranslatedText(noticia.tiempoHace,
                        style: TextStyle(color: const Color.fromARGB(221, 255, 255, 255), fontSize: 11)),
                  ],
                ),
                SizedBox(height: 12),
                TranslatedText(noticia.titulo,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3)),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time_outlined,
                        color: const Color.fromARGB(137, 56, 55, 55), size: 14),
                    SizedBox(width: 6),
                    TranslatedText(noticia.tiempoLectura,
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Spacer(),
                    IconButton(
                        icon: Icon(Icons.bookmark_border_outlined,
                            color: Colors.white54, size: 18),
                        onPressed: () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
