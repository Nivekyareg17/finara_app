import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://finara-api-1lmd.onrender.com";

  static Map<String, String> _jsonHeaders([String? token]) {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  static dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (e) {
      print("JSON DECODE ERROR: $e");
      print("BODY: ${response.body}");
      return null;
    }
  }

  static List<dynamic> _decodeList(http.Response response, String label) {
    if (response.statusCode != 200) {
      print("$label STATUS: ${response.statusCode}");
      print("$label BODY: ${response.body}");
      return [];
    }

    final data = _decode(response);
    if (data is List) return data;

    print("$label esperaba una lista y recibio: $data");
    return [];
  }

  static Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: _jsonHeaders(),
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = _decode(response);
      return data is Map ? data["access_token"] : null;
    }

    print("Error login: ${response.body}");
    return null;
  }

  static Future<bool> register(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: _jsonHeaders(),
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );

    print("REGISTER STATUS: ${response.statusCode}");
    print("REGISTER BODY: ${response.body}");

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<Map<String, dynamic>?> getUser(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/users/me"),
      headers: _jsonHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = _decode(response);
      return data is Map<String, dynamic> ? data : null;
    }

    print("GET USER STATUS: ${response.statusCode}");
    print("GET USER BODY: ${response.body}");
    return null;
  }

  static Future<bool> createTransaction(
    String token,
    String type,
    double amount,
    String description,
    int categoryId,
    DateTime date,
  ) async {
    final body = jsonEncode({
      "type": type.toLowerCase(),
      "amount": amount,
      "description": description,
      "category_id": categoryId,
      "date": date.toIso8601String(),
    });

    final response = await http.post(
      Uri.parse("$baseUrl/transactions/"),
      headers: _jsonHeaders(token),
      body: body,
    );

    print("CREATE TRANSACTION STATUS: ${response.statusCode}");
    print("CREATE TRANSACTION BODY: ${response.body}");

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<dynamic>> getTransactions(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/transactions/"),
      headers: _jsonHeaders(token),
    );

    return _decodeList(response, "GET TRANSACTIONS");
  }

  static Future<bool> updateTransaction(
    String token,
    int id,
    String type,
    double amount,
    String description,
    int categoryId,
    DateTime date,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/transactions/$id"),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        "type": type.toLowerCase(),
        "amount": amount,
        "description": description,
        "category_id": categoryId,
        "date": date.toIso8601String(),
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> deleteTransaction(String token, int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/transactions/$id"),
      headers: _jsonHeaders(token),
    );

    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getTransactionCategories(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/categories/"),
        headers: _jsonHeaders(token),
      );

      if (response.statusCode == 404 || response.statusCode == 405) {
        final fallbackResponse = await http.get(
          Uri.parse("$baseUrl/categories"),
          headers: _jsonHeaders(token),
        );
        return _decodeList(fallbackResponse, "GET CATEGORIES FALLBACK");
      }

      return _decodeList(response, "GET CATEGORIES");
    } catch (e) {
      print("GET CATEGORIES ERROR: $e");
      return [];
    }
  }

  static Future<bool> createCategory(
      String token, String name, String type) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/categories/"),
        headers: _jsonHeaders(token),
        body: jsonEncode({"name": name, "type": type}),
      );

      print("CREATE CATEGORY STATUS: ${response.statusCode}");
      print("CREATE CATEGORY BODY: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("CREATE CATEGORY ERROR: $e");
      return false;
    }
  }

  static Future<bool> updateCategory(
    String token,
    int id,
    String name,
    String type,
  ) async {
    try {
      final cleanBaseUrl = baseUrl.endsWith("/")
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      final body = jsonEncode({"name": name, "type": type});
      final urls = [
        Uri.parse("$cleanBaseUrl/categories/categories/$id"),
        Uri.parse("$cleanBaseUrl/categories/$id"),
      ];

      for (final url in urls) {
        print("Intentando PUT a: $url");
        final response = await http.put(
          url,
          headers: _jsonHeaders(token),
          body: body,
        );

        print("UPDATE CATEGORY STATUS: ${response.statusCode}");
        print("UPDATE CATEGORY BODY: ${response.body}");

        if (response.statusCode == 200) return true;
        if (response.statusCode != 404 && response.statusCode != 405) {
          return false;
        }
      }

      return false;
    } catch (e) {
      print("UPDATE CATEGORY ERROR: $e");
      return false;
    }
  }

  static Future<bool> deleteCategory(String token, int id) async {
    try {
      final cleanBaseUrl = baseUrl.endsWith("/")
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;

      print("🕵️‍♂️ --- INICIANDO BORRADO DE CATEGORÍA ID: $id ---");

      // Primer intento: Sin barra al final
      final urlSinSlash = Uri.parse("$cleanBaseUrl/categories/$id");
      print("👉 Intento 1 | URL: $urlSinSlash");

      var response =
          await http.delete(urlSinSlash, headers: _jsonHeaders(token));
      print("📡 Intento 1 | STATUS: ${response.statusCode}");
      print("📦 Intento 1 | BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("✅ ¡Categoría borrada con éxito en el intento 1!");
        return true;
      }

      // Si nos dio error, intentamos con la barra al final (por si FastAPI pide el 307)
      print("🔄 Falló el intento 1. Probando con barra final (/) ...");
      final urlConSlash = Uri.parse("$cleanBaseUrl/categories/$id/");
      print("👉 Intento 2 | URL: $urlConSlash");

      response = await http.delete(urlConSlash, headers: _jsonHeaders(token));
      print("📡 Intento 2 | STATUS: ${response.statusCode}");
      print("📦 Intento 2 | BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("✅ ¡Categoría borrada con éxito en el intento 2!");
        return true;
      }

      print(
          "❌ Ningún intento funcionó. Revisa los códigos de error de arriba.");

      // Una posible razón es que la categoría tenga transacciones asociadas (Error 500 o 400)
      if (response.statusCode == 500 || response.statusCode == 400) {
        print(
            "⚠️ CUIDADO: Puede que no te deje borrarla porque hay transacciones usando esta categoría.");
      }

      return false;
    } catch (e) {
      print("🚨 ERROR FATAL AL ELIMINAR CATEGORÍA: $e");
      return false;
    }
  }

  static Future<bool> resetPassword(String token, String newPassword) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/reset-password"),
            headers: _jsonHeaders(),
            body: jsonEncode({"token": token, "new_password": newPassword}),
          )
          .timeout(const Duration(seconds: 60));

      return response.statusCode == 200;
    } catch (e) {
      print("RESET PASSWORD ERROR: $e");
      return false;
    }
  }

  static Future<bool> forgotPassword(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/forgot-password"),
            headers: _jsonHeaders(),
            body: jsonEncode({"email": email}),
          )
          .timeout(const Duration(seconds: 60));

      return response.statusCode == 200;
    } catch (e) {
      print("FORGOT PASSWORD ERROR: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getUsers(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/users/all"),
      headers: _jsonHeaders(token),
    );

    return _decodeList(response, "GET USERS");
  }

  static Future<void> deleteUser(String token, int id) async {
    await http.delete(
      Uri.parse("$baseUrl/users/delete/$id"),
      headers: _jsonHeaders(token),
    );
  }

  static Future<void> makeAdmin(String token, int id) async {
    await http.put(
      Uri.parse("$baseUrl/users/make-admin/$id"),
      headers: _jsonHeaders(token),
    );
  }

  static Future<void> removeAdmin(String token, int id) async {
    await http.put(
      Uri.parse("$baseUrl/users/remove-admin/$id"),
      headers: _jsonHeaders(token),
    );
  }

  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(Uri.parse("$baseUrl/videos/categories"));
    return _decodeList(response, "GET VIDEO CATEGORIES");
  }

  static Future<List<dynamic>> getVideos(int categoryId) async {
    final response = await http.get(Uri.parse("$baseUrl/videos/$categoryId"));
    return _decodeList(response, "GET VIDEOS");
  }

  static Future<bool> createVideoCategory(
      String title, String description) async {
    final response = await http.post(
      Uri.parse("$baseUrl/videos/categories"),
      headers: _jsonHeaders(),
      body: jsonEncode({"title": title, "description": description}),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> updateVideoCategory(
    int id,
    String title,
    String description,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/videos/categories/$id"),
      headers: _jsonHeaders(),
      body: jsonEncode({"title": title, "description": description}),
    );

    return response.statusCode == 200;
  }

  static Future<bool> deleteVideoCategory(int id) async {
    final response =
        await http.delete(Uri.parse("$baseUrl/videos/categories/$id"));
    return response.statusCode == 200;
  }

  static Future<bool> createVideo(
      String title, String url, int categoryId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/videos/"),
      headers: _jsonHeaders(),
      body: jsonEncode({"title": title, "url": url, "category_id": categoryId}),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> updateVideo(
    int id,
    String title,
    String url,
    int categoryId,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/videos/$id"),
      headers: _jsonHeaders(),
      body: jsonEncode({"title": title, "url": url, "category_id": categoryId}),
    );

    return response.statusCode == 200;
  }

  static Future<bool> deleteVideo(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/videos/$id"));
    return response.statusCode == 200;
  }

  Future<List<dynamic>> obtenerLecturas() async {
    final response = await http.get(Uri.parse("$baseUrl/api/lecturas/"));
    return _decodeList(response, "GET LECTURAS");
  }

  static Future<List<dynamic>> getLecturas() async {
    final response = await http.get(Uri.parse("$baseUrl/api/lecturas/"));
    return _decodeList(response, "GET LECTURAS");
  }

  static Future<bool> createLectura(
    String titulo,
    String contenido,
    String tiempoLectura,
  ) async {
    if (titulo.trim().isEmpty ||
        contenido.trim().isEmpty ||
        tiempoLectura.trim().isEmpty) {
      print("Error: campos vacios en createLectura");
      return false;
    }

    final response = await http.post(
      Uri.parse("$baseUrl/api/lecturas/"),
      headers: _jsonHeaders(),
      body: jsonEncode({
        "titulo": titulo.trim(),
        "contenido": contenido.trim(),
        "tiempo_lectura": tiempoLectura.trim(),
      }),
    );

    print("CREATE LECTURA STATUS: ${response.statusCode}");
    print("CREATE LECTURA BODY: ${response.body}");

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> deleteLectura(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/api/lecturas/$id"));

    print("DELETE LECTURA STATUS: ${response.statusCode}");
    print("DELETE LECTURA BODY: ${response.body}");

    return response.statusCode == 200;
  }

  static Future<bool> updateLectura(
    int id,
    String titulo,
    String contenido,
    String tiempoLectura,
  ) async {
    if (titulo.trim().isEmpty ||
        contenido.trim().isEmpty ||
        tiempoLectura.trim().isEmpty) {
      print("Error: campos vacios en updateLectura");
      return false;
    }

    final response = await http.put(
      Uri.parse("$baseUrl/api/lecturas/$id"),
      headers: _jsonHeaders(),
      body: jsonEncode({
        "titulo": titulo.trim(),
        "contenido": contenido.trim(),
        "tiempo_lectura": tiempoLectura.trim(),
      }),
    );

    print("UPDATE LECTURA STATUS: ${response.statusCode}");
    print("UPDATE LECTURA BODY: ${response.body}");

    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getMessages(String token, int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/messages/$userId"),
      headers: _jsonHeaders(token),
    );

    return _decodeList(response, "GET MESSAGES");
  }

  static Future<Map<String, bool>> getBlockStatus(
    String token,
    int userId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/messages/blocked/$userId"),
      headers: _jsonHeaders(token),
    );

    if (response.statusCode != 200) {
      return {
        "blocked": false,
        "blocked_by_me": false,
        "blocked_me": false,
      };
    }

    final data = _decode(response);
    if (data is! Map) {
      return {
        "blocked": false,
        "blocked_by_me": false,
        "blocked_me": false,
      };
    }

    return {
      "blocked": data["blocked"] == true,
      "blocked_by_me": data["blocked_by_me"] == true,
      "blocked_me": data["blocked_me"] == true,
    };
  }

  static Future<bool> isUserBlocked(String token, int userId) async {
    final status = await getBlockStatus(token, userId);
    return status["blocked"] == true;
  }

  static Future<bool> blockUser(String token, int userId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/messages/block/$userId"),
      headers: _jsonHeaders(token),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> unblockUser(String token, int userId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/messages/block/$userId"),
      headers: _jsonHeaders(token),
    );

    return response.statusCode == 200;
  }

  static Future<bool> sendMessage(
    String token,
    int receiverId,
    String content,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/messages/"),
      headers: _jsonHeaders(token),
      body: jsonEncode({"receiver_id": receiverId, "content": content}),
    );

    print("SEND MESSAGE STATUS: ${response.statusCode}");
    print("SEND MESSAGE BODY: ${response.body}");

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<dynamic>> getUsersPublic(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/users/"),
      headers: _jsonHeaders(token),
    );

    return _decodeList(response, "GET PUBLIC USERS");
  }

  static Future<Map<String, dynamic>?> searchUserByEmail(
    String token,
    String email,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/messages/search?email=${Uri.encodeComponent(email)}",
      ),
      headers: _jsonHeaders(token),
    );

    if (response.statusCode != 200) {
      return null;
    }

    final data = _decode(response);

    return data is Map<String, dynamic> ? data : null;
  }

  static Future<Map<String, dynamic>> sendMessageRequest(
    String token,
    int receiverId,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/messages/request"),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        "receiver_id": receiverId,
      }),
    );

    print("REQUEST STATUS: ${response.statusCode}");
    print("REQUEST BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        "success": true,
        "message": "Solicitud enviada",
      };
    }

    final data = jsonDecode(response.body);

    return {
      "success": false,
      "message": data["detail"] ?? "Error desconocido",
    };
  }

  static Future<List<dynamic>> getRequests(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/messages/requests"),
      headers: _jsonHeaders(token),
    );

    return _decodeList(response, "GET REQUESTS");
  }

  static Future<bool> acceptRequest(
    String token,
    int requestId,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/messages/request/$requestId/accept"),
      headers: _jsonHeaders(token),
    );

    return response.statusCode == 200;
  }

  static Future<bool> rejectRequest(
    String token,
    int requestId,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/messages/request/$requestId/reject"),
      headers: _jsonHeaders(token),
    );

    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getChats(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/messages/chats",
      ),
      headers: _jsonHeaders(token),
    );

    return _decodeList(
      response,
      "GET CHATS",
    );
  }
}
