import 'package:flutter/material.dart';

// Modelo de datos para las noticias
class NoticiaAPI {
  final String categoria;
  final String tiempoHace;
  final String titulo;
  final String tiempoLectura;

  NoticiaAPI({
    required this.categoria,
    required this.tiempoHace,
    required this.titulo,
    required this.tiempoLectura,
  });
}