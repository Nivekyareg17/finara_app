// Este archivo envía HTTP request al backend
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://finara-app.onrender.com";

  static Future<String?> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/auth/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data["access_token"];
    } else {
      print("Error login: ${response.body}");
      return null;
    }
  }

  static Future<bool> register(
    String name,
    String email,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/auth/register");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Error register: ${response.body}");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUser(String token) async {
    final url = Uri.parse("$baseUrl/users/me");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }
}


