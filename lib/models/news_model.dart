// Modelo de datos para las noticias
class NoticiaAPI {
  final String categoria;
  final String tiempoHace;
  final String titulo;
  final String tiempoLectura;
  final String imagen;
  final String url;

  NoticiaAPI({
    required this.categoria,
    required this.tiempoHace,
    required this.titulo,
    required this.tiempoLectura,
    required this.imagen,
    required this.url,
  });
}
