import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meta_ahorro.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final storage = const FlutterSecureStorage();

  String? _token;
  Map<String, dynamic>? _user;
  List<MetaAhorro> _metas = [];

  AuthProvider() {
    loadMetas();
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  List<MetaAhorro> get metas => _metas;
  bool get isAdmin => _user?["role"] == "admin";
  String? get userName => _user?["name"];


  Future<bool> login(String email, String password) async {
    final token = await ApiService.login(email, password);

    if (token != null) {
      _token = token;
      await storage.write(key: "jwt_token", value: token);

      _user = await ApiService.getUser(token);

      await loadMetas();
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    return await ApiService.register(name, email, password);
  }

  Future<void> loadToken() async {
    final savedToken = await storage.read(key: "jwt_token");

    if (savedToken != null) {
      _token = savedToken;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
     _user = null;
    await storage.delete(key: "jwt_token");
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (_token == null) return null;

    final user = await ApiService.getUser(_token!);

    if (user == null) {
      await logout();
    }else{
      _user = user;
    }

    return user;
  }

  // Lógica para alternar entre vista de admin y usuario
  bool _isAdminView = false;



bool get isAdminView => _isAdminView;

void toggleView() {
  if (!isAdmin) return;
  _isAdminView = !_isAdminView;
  notifyListeners();
}

  // Métodos relacionados con metas de ahorro
  Future<void> loadMetas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("metas_ahorro");
    if (raw == null || raw.isEmpty) return;

    try {
      final data = jsonDecode(raw);
      if (data is List) {
        _metas = data
            .map((e) => MetaAhorro.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        notifyListeners();
      }
    } catch (_) {
      _metas = [];
    }
  }

  Future<void> _saveMetas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "metas_ahorro",
      jsonEncode(_metas.map((meta) => meta.toJson()).toList()),
    );
  }

  Future<void> addMeta(MetaAhorro meta) async {
    _metas = [..._metas, meta];
    notifyListeners();
    await _saveMetas();
    notifyListeners();
  }

  Future<void> actualizarMetasConIngreso(double ingreso) async {
    for (var meta in _metas) {
      final aporte = ingreso * 0.1;
      meta.montoActual += aporte;
      if (aporte > 0) {
        meta.aportes.insert(0, MetaAporte(monto: aporte));
      }
    }
    await _saveMetas();
    notifyListeners();
  }

  Future<void> logoutM() async {
    _token = null;
    _metas.clear();

    await storage.delete(key: "jwt_token");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("metas_ahorro");

    notifyListeners();
  }

  Future<void> editarMeta(int index, MetaAhorro nueva) async {
    _metas[index] = nueva;
    await _saveMetas();
    notifyListeners();
  }

  Future<void> agregarDineroMeta(int index, double monto) async {
    if (index < 0 || index >= _metas.length || monto <= 0) return;

    _metas[index].montoActual += monto;
    _metas[index].aportes.insert(0, MetaAporte(monto: monto));

    await _saveMetas();
    notifyListeners();
  }

  Future<void> eliminarMeta(int index) async {
    _metas.removeAt(index);
    await _saveMetas();
    notifyListeners();
  }
}


//code felipe
//String? get token => _token;
//  bool get isAuthenticated => _token != null;
//  List<MetaAhorro> get metas => _metas;
//  bool get isAdmin => _user?["role"] == "admin";//admin-vs-usuario
