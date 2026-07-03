import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note.dart';

class NoteService {
  final String baseUrl = "https://finara-app-rc3x.onrender.com/notes";

  Future<List<Note>> fetchNotes(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("📡 STATUS FETCH: ${response.statusCode}");
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((n) => Note.fromJson(n)).toList();
      }
      return [];
    } catch (e) {
      print("🚨 Error en fetchNotes: $e");
      return [];
    }
  }

  Future<bool> createNote(Note note, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(note.toJson()),
      );
      print("📡 STATUS CREAR: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("🚨 Error en createNote: $e");
      return false;
    }
  }

  Future<bool> updateNote(Note note, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${note.id}/'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(note.toJson()),
      );
      print("📡 STATUS ACTUALIZAR: ${response.statusCode}");
      return response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204;
    } catch (e) {
      print("🚨 Error en updateNote: $e");
      return false;
    }
  }

  Future<bool> deleteNote(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id/'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      print("📡 STATUS ELIMINAR: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("🚨 Error en deleteNote: $e");
      return false;
    }
  }
}
