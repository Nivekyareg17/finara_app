// Este archivo envía HTTP request al backend
import 'dart:convert';
import 'package:http/http.dart' as http;


class ApiService {
  static const String baseUrl = "https://finara-api.onrender.com";

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

  // CREAR transacción
  static Future<bool> createTransaction(
    String token,
    String type,
    double amount,
    String description,
  ) async {
    final url = Uri.parse("$baseUrl/transactions/");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "type": type,
        "amount": amount,
        "description": description,
      }),
    );

    if (response.statusCode == 400) {
      print("Duplicado");
    }

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    return response.statusCode == 200 || response.statusCode == 201;
  }

// OBTENER transacciones
  static Future<List<dynamic>> getTransactions(String token) async {
    final url = Uri.parse("$baseUrl/transactions/");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<bool> updateTransaction(
    String token,
    int id,
    String type,
    double amount,
    String description,
  ) async {
    final url = Uri.parse("$baseUrl/transactions/$id");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "type": type,
        "amount": amount,
        "description": description,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> deleteTransaction(String token, int id) async {
    final url = Uri.parse("$baseUrl/transactions/$id");

    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return response.statusCode == 200;
  }

  static Future<bool> resetPassword(String token, String newPassword) async {
    final url = Uri.parse("$baseUrl/auth/reset-password");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "token": token,
              "new_password": newPassword,
            }),
          )
          .timeout(const Duration(seconds: 60));

      print("RESET STATUS: ${response.statusCode}");
      print("RESET BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("ERROR RESET PASSWORD: $e");
      return false;
    }
  }

  static Future<bool> forgotPassword(String email) async {
    final url = Uri.parse("$baseUrl/auth/forgot-password");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email}),
          )
          .timeout(const Duration(seconds: 60));

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("ERROR FORGOT PASSWORD: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getUsers(String token) async {
    final url = Uri.parse("$baseUrl/users/all");

    final res =
        await http.get(url, headers: {"Authorization": "Bearer $token"});

    print("STATUS USERS: ${res.statusCode}");
    print("BODY USERS: ${res.body}");

    return jsonDecode(res.body);
  }

  static Future<void> deleteUser(String token, int id) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/users/delete/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    print("DELETE STATUS: ${res.statusCode}");
    print("DELETE BODY: ${res.body}");
  }

  static Future<void> makeAdmin(String token, int id) async {
    await http.put(
      Uri.parse("$baseUrl/users/make-admin/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  static Future<void> removeAdmin(String token, int id) async {
    await http.put(
      Uri.parse("$baseUrl/users/remove-admin/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(Uri.parse("$baseUrl/videos/categories"));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error al cargar categorías");
    }
  }

  // Obtener videos por categoría
  static Future<List<dynamic>> getVideos(int categoryId) async {
    final response =
        await http.get(Uri.parse("$baseUrl/videos/$categoryId"));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error al cargar videos");
    }
  }
}
