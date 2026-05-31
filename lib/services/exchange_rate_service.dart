import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  static const _cachePrefix = "exchange_rates_";

  static Future<Map<String, double>> getRatesForBase(String base) async {
    final normalizedBase = base.toUpperCase();
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = "$_cachePrefix$normalizedBase";
    final cachedRaw = prefs.getString(cacheKey);

    if (cachedRaw != null) {
      final cached = _decodeCache(cachedRaw);
      final cachedDate = cached["date"] as String?;
      if (cachedDate == _todayKey()) {
        return Map<String, double>.from(cached["rates"] as Map);
      }
    }

    try {
      final response = await http
          .get(
            Uri.parse("https://open.er-api.com/v6/latest/$normalizedBase"),
            headers: {"Accept": "application/json"},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final rates = body["rates"];
        if (rates is Map) {
          final parsedRates = rates.map(
            (key, value) => MapEntry(
              key.toString().toUpperCase(),
              (value as num).toDouble(),
            ),
          );
          await prefs.setString(
            cacheKey,
            jsonEncode({
              "date": _todayKey(),
              "rates": parsedRates,
            }),
          );
          return parsedRates;
        }
      }
    } catch (_) {
      // Fallback below uses the last cache, keeping the UI usable offline.
    }

    if (cachedRaw != null) {
      final cached = _decodeCache(cachedRaw);
      return Map<String, double>.from(cached["rates"] as Map);
    }

    return {normalizedBase: 1.0};
  }

  static Map<String, dynamic> _decodeCache(String raw) {
    final data = jsonDecode(raw);
    final rawRates = data["rates"] as Map;
    return {
      "date": data["date"]?.toString(),
      "rates": rawRates.map(
        (key, value) => MapEntry(
          key.toString().toUpperCase(),
          (value as num).toDouble(),
        ),
      ),
    };
  }

  static String _todayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
}
