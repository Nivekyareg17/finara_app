import 'package:finara_app_v1/services/news_services.dart';
import 'package:flutter/material.dart';
import '../../models/news_model.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:url_launcher/url_launcher.dart';

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
            Text(
              "Finara News",
              style: TextStyle(
                  color:Color.fromARGB(255, 10, 109, 82),
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ],
        ),
      ),
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

  // 1. Barra de Cotizaciones Superior (Ticker)
  Widget _buildStockTicker() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTickerItem("BTC", "+64,231.50", "+1.2%", Colors.greenAccent),
            _buildDivider(),
            _buildTickerItem("S&P 500", "-0.45%", "", Colors.redAccent,
                isIndex: true),
            _buildDivider(),
            _buildTickerItem("ETH", "+3,450.2", "+2.1%", Colors.greenAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildTickerItem(
      String symbol, String price, String change, Color color,
      {bool isIndex = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(symbol,
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              if (change.isNotEmpty) ...[
                SizedBox(width: 4),
                Text(change,
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ],
          ),
          SizedBox(height: 2),
          Text(price,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
        height: 30,
        width: 1,
        color: Colors.white24,
        margin: EdgeInsets.symmetric(horizontal: 4));
  }

  // 2. Encabezado de Sección y Botón de Filtros
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("ÚLTIMAS NOTICIAS",
            style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0)),
        TextButton.icon(
          onPressed: () => print("Filtros"),
          icon: Icon(Icons.filter_list, color: Colors.white54, size: 16),
          label: Text("Filtros",
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ),
      ],
    );
  }

  // 3. Tarjeta de Noticia Principal
  Widget _buildNewsCard(NoticiaAPI noticia) {
    return Container(
      decoration: BoxDecoration(
          color: Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: noticia.categoria == "CRIPTO"
                            ? Color(0xFF673AB7).withOpacity(0.2)
                            : Color(0xFF00C853).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(noticia.categoria,
                          style: TextStyle(
                              color: noticia.categoria == "CRIPTO"
                                  ? Color(0xFFBB86FC)
                                  : Color(0xFF00C853),
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: 8),
                    Text(noticia.tiempoHace,
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                SizedBox(height: 12),
                Text(noticia.titulo,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3)),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time_outlined,
                        color: Colors.white54, size: 14),
                    SizedBox(width: 6),
                    Text(noticia.tiempoLectura,
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
