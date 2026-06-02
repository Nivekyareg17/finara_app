import 'package:finara_app_v1/models/category_model.dart';
import 'package:finara_app_v1/providers/auth_provider.dart';
import 'package:finara_app_v1/screens/calculators/calculators_screen.dart';
import 'package:finara_app_v1/widgets/custom_bottom_nav.dart';
import 'package:finara_app_v1/widgets/translate_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finara_app_v1/providers/theme_provider.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:finara_app_v1/providers/languaje_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finara_app_v1/models/meta_ahorro.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/exchange_rate_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;

    // Quita cualquier cosa que no sea nÃºmero
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Convierte a numero y formatea (ejemplo: 1000 -> 1.000)
    double value = double.parse(newText) / 100; // Divide por 100 para centavos
    final formatter =
        NumberFormat.currency(locale: 'es_CO', symbol: '', decimalDigits: 2);
    String formatted = formatter.format(value).trim();

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

Map<String, dynamic> _getCategoryData(String description) {
  // Comparamos la descripcion para asignar icono y color
  String desc = description.toLowerCase();
  if (desc.contains("mercado")) {
    return {'icon': Icons.shopping_basket_rounded, 'color': Colors.orange};
  } else if (desc.contains("pago") || desc.contains("trabajo")) {
    return {'icon': Icons.work_rounded, 'color': Colors.blue};
  } else if (desc.contains("ahorro")) {
    return {'icon': Icons.savings_rounded, 'color': Colors.pink};
  } else if (desc.contains("gasto") || desc.contains("adicional")) {
    return {'icon': Icons.add_circle_outline_rounded, 'color': Colors.purple};
  }
  return {'icon': Icons.category_rounded, 'color': Colors.grey};
}

class _ProfileScreenState extends State<ProfileScreen> {
  final NumberFormat formatter = NumberFormat("#,##0.00", "en_US");

  String? profileImageUrl;
  Uint8List? _localProfileImageBytes;
  String name = "";
  String email = "";
  String username = "";
  String age = "";
  String description = "";
  String phone = "";

  List<TransactionModel> transactions = [];
  List<CategoryModel> categories = [];
  String movementFilter = "todos";
  bool _showAllMovements = false;
  String baseCurrency = "COP";
  Map<String, double> exchangeRates = {"COP": 1};

  static const Map<String, String> supportedCurrencies = {
    "COP": "Peso colombiano",
    "USD": "Dolar estadounidense",
    "EUR": "Euro",
    "MXN": "Peso mexicano",
    "ARS": "Peso argentino",
    "BRL": "Real brasileno",
    "GBP": "Libra esterlina",
    "CAD": "Dolar canadiense",
    "CLP": "Peso chileno",
    "PEN": "Sol peruano",
    "JPY": "Yen japones",
    "CHF": "Franco suizo",
  };

  static const Map<String, String> currencySymbols = {
    "COP": "\$",
    "USD": "US\$",
    "EUR": "€",
    "MXN": "MX\$",
    "ARS": "AR\$",
    "BRL": "R\$",
    "GBP": "£",
    "CAD": "CA\$",
    "CLP": "CLP\$",
    "PEN": "S/",
    "JPY": "¥",
    "CHF": "CHF",
  };

  String selectedChartType = "gasto";
  int activeChartPage = 0;

  @override
  void initState() {
    super.initState();
    loadUser();
    _loadCurrencySettings();
    _loadData();
  }

  ImageProvider? _profileImageProvider() {
    final localBytes = _localProfileImageBytes;
    if (localBytes != null && localBytes.isNotEmpty) {
      return MemoryImage(localBytes);
    }

    final rawUrl = profileImageUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) return null;

    if (rawUrl.startsWith("data:")) {
      try {
        final commaIndex = rawUrl.indexOf(",");
        if (commaIndex != -1) {
          final imageData = rawUrl.substring(commaIndex + 1).split("?").first;
          return MemoryImage(base64Decode(imageData));
        }
      } catch (_) {
        return null;
      }
    }

    if (!kIsWeb && !rawUrl.startsWith("http") && File(rawUrl).existsSync()) {
      return FileImage(File(rawUrl));
    }

    final cleanUrl = rawUrl.split("?").first;
    final version = rawUrl.contains("?") ? "?${rawUrl.split("?").last}" : "";
    final normalized = rawUrl.startsWith("http")
        ? rawUrl
        : "${ApiService.baseUrl}${cleanUrl.startsWith("/") ? "" : "/"}$cleanUrl$version";
    return NetworkImage(normalized);
  }

  Widget _profileAvatar({
    required double radius,
    double? iconSize,
    bool bordered = false,
  }) {
    final imageProvider = _profileImageProvider();
    final size = radius * 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallback = ColoredBox(
      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: iconSize ?? radius,
          color: isDark ? Colors.white70 : const Color(0xFF64748B),
        ),
      ),
    );

    final avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageProvider == null
            ? fallback
            : Image(
                image: imageProvider,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => fallback,
              ),
      ),
    );

    if (!bordered) return avatar;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.32), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: avatar,
        ),
      ),
    );
  }

  MediaType _imageMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith(".png")) return MediaType("image", "png");
    if (lower.endsWith(".webp")) return MediaType("image", "webp");
    if (lower.endsWith(".gif")) return MediaType("image", "gif");
    return MediaType("image", "jpeg");
  }

  Future<void> _loadCurrencySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString("base_currency") ?? "COP";
    if (!mounted) return;
    setState(() => baseCurrency = savedCurrency.toUpperCase());
    await _refreshExchangeRates();
  }

  Future<void> _refreshExchangeRates() async {
    final rates = await ExchangeRateService.getRatesForBase(baseCurrency);
    if (!mounted) return;
    setState(() => exchangeRates = rates);
  }

  Future<Map<String, String>> _loadCategoryCurrencyPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("category_currencies");
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString().toUpperCase()),
    );
  }

  Future<void> _saveCategoryCurrency(String categoryId, String currency) async {
    final prefs = await SharedPreferences.getInstance();
    final currencies = await _loadCategoryCurrencyPrefs();
    currencies[categoryId] = currency.toUpperCase();
    await prefs.setString("category_currencies", jsonEncode(currencies));
  }

  Future<Map<String, String>> _loadTransactionCurrencyPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("transaction_currencies");
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString().toUpperCase()),
    );
  }

  Future<void> _saveTransactionCurrency(int transactionId, String currency) async {
    final prefs = await SharedPreferences.getInstance();
    final currencies = await _loadTransactionCurrencyPrefs();
    currencies[transactionId.toString()] = currency.toUpperCase();
    await prefs.setString("transaction_currencies", jsonEncode(currencies));
  }

  String _categoryCurrencyById(int? categoryId) {
    if (categoryId == null) return baseCurrency;
    try {
      return categories
          .firstWhere((category) => int.parse(category.id) == categoryId)
          .currency
          .toUpperCase();
    } catch (_) {
      return baseCurrency;
    }
  }

  String _transactionCurrency(TransactionModel transaction) {
    if (transaction.currency.trim().isNotEmpty) {
      return transaction.currency.toUpperCase();
    }
    return _categoryCurrencyById(int.tryParse(transaction.categoryId));
  }

  double _convertToBase(double amount, String currency) {
    final normalized = currency.toUpperCase();
    if (normalized == baseCurrency) return amount;
    final rate = exchangeRates[normalized];
    if (rate == null || rate == 0) return amount;
    return amount / rate;
  }

  String _currencyLabel(String code) {
    final normalized = code.toUpperCase();
    final name = supportedCurrencies[normalized] ?? normalized;
    return "$normalized - $name";
  }

  Future<void> _selectBaseCurrency() async {
    final selected = await _showCurrencyPicker(baseCurrency);
    if (selected == null || selected == baseCurrency) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("base_currency", selected);
    if (!mounted) return;
    setState(() => baseCurrency = selected);
    await _refreshExchangeRates();
    _showTopNotice(
      "Moneda base actualizada a $selected",
      isError: false,
      icon: Icons.currency_exchange_rounded,
    );
  }

  Future<String?> _showCurrencyPicker(String currentCurrency) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF10231E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Moneda",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                  children: [
                    ...supportedCurrencies.entries.map((entry) {
                      final selected = entry.key == currentCurrency;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: selected
                              ? const Color(0xFF064E3B)
                              : const Color(0xFFE2E8F0),
                          child: Text(
                            currencySymbols[entry.key] ?? entry.key,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: Text(entry.value),
                        trailing: selected
                            ? const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF10B981))
                            : null,
                        onTap: () => Navigator.pop(context, entry.key),
                      );
                    }),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE2E8F0),
                        child: Icon(Icons.add_rounded, color: Colors.black87),
                      ),
                      title: const Text(
                        "Otra moneda",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle:
                          const Text("Escribe un codigo ISO, ej: DOP, UYU, CNY"),
                      onTap: () async {
                        final custom = await _askCustomCurrency();
                        if (custom != null && context.mounted) {
                          Navigator.pop(context, custom);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _askCustomCurrency() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Agregar moneda"),
              content: TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 3,
                decoration: InputDecoration(
                  labelText: "Codigo ISO",
                  hintText: "Ej: USD",
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim().toUpperCase();
                    if (!RegExp(r'^[A-Z]{3}$').hasMatch(value)) {
                      setStateDialog(() {
                        errorText = "Usa 3 letras, por ejemplo COP";
                      });
                      return;
                    }
                    Navigator.pop(context, value);
                  },
                  child: const Text("Usar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportMovementsPdf() async {
    await PdfService.exportTransactionsPdf(
      transactions: transactions,
      name: name.isEmpty ? "Usuario Finara" : name,
      email: email.isEmpty ? "Sin email" : email,
      getCategoryName: getCategoryName,
      formatCurrency: formatCurrency,
      balance: getBalance(),
      getTransactionCurrency: _transactionCurrency,
      baseCurrency: baseCurrency,
      totalIngresos: getTotalIngresos(),
      totalGastos: getTotalGastos(),
    );

    if (!mounted) return;
    _showTopNotice(
      "PDF generado correctamente",
      isError: false,
      icon: Icons.picture_as_pdf_rounded,
    );
  }

  Future<void> loadTransactions() async {
    final auth = context.read<AuthProvider>();

    final data = await ApiService.getTransactions(auth.token!);
    final currencyPrefs = await _loadTransactionCurrencyPrefs();

    print(data);

    try {
      final loadedTransactions =
          data.map((e) {
        final transaction = TransactionModel.fromMap(e);
        final savedCurrency = currencyPrefs[transaction.id.toString()];
        if (savedCurrency != null) {
          transaction.currency = savedCurrency;
        }
        return transaction;
      }).toList();

      print("TRANSACCIONES OK");

      if (!mounted) return;

      setState(() {
        transactions = loadedTransactions;
      });
    } catch (e) {
      print("ERROR PARSEANDO TRANSACCIONES");
      print(e);
    }
  }

  void loadUser() async {
    try {
      final auth = context.read<AuthProvider>();
      final data = await auth.getUserData();
      print(data);

      setState(() {
        if (data != null) {
          name = data["name"] ?? "Sin nombre";
          email = data["email"] ?? "Sin email";
          profileImageUrl = data["profile_image_url"];
          username = data["username"] ?? "";
          age = data["age"]?.toString() ?? "";
          description = data["description"] ?? "";
          phone = data["phone"] ?? "";
        } else {
          name = "No se pudo cargar";
          email = "";
        }
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        name = "Error cargando";
        email = "";
      });
    }
  }

  Future<void> _loadData() async {
    await loadCategories();
    await loadTransactions();
  }

  Future<void> loadCategories() async {
    final auth = context.read<AuthProvider>();
    final data = await ApiService.getTransactionCategories(auth.token!);
    final currencyPrefs = await _loadCategoryCurrencyPrefs();

    if (!mounted) return;

    setState(() {
      categories = data.map((e) {
        final category = CategoryModel.fromMap(e);
        return category.copyWith(
          currency: currencyPrefs[category.id] ?? category.currency,
        );
      }).toList();
    });
  }

  String getCategoryName(int categoryId) {
    try {
      return categories
          .firstWhere(
            (c) => int.parse(c.id) == categoryId,
          )
          .name;
    } catch (e) {
      return "General";
    }
  }

  double getBalance() {
    double total = 0;

    for (var t in transactions) {
      if (t.type == "ingreso") {
        total += _convertToBase(t.amount, _transactionCurrency(t));
      } else {
        total -= _convertToBase(t.amount, _transactionCurrency(t));
      }
    }

    return total;
  }

  double getTotalIngresos() {
    return transactions
        .where((t) => t.type == "ingreso")
        .fold(0.0, (sum, t) => sum + _convertToBase(t.amount, _transactionCurrency(t)));
  }

  double getTotalGastos() {
    return transactions
        .where((t) => t.type == "gasto")
        .fold(0.0, (sum, t) => sum + _convertToBase(t.amount, _transactionCurrency(t)));
  }

  double getTotalGeneral() {
    return getTotalIngresos() + getTotalGastos();
  }

  int? _findSavedTransactionId({
    required String type,
    required double amount,
    required String description,
    required int categoryId,
    required DateTime date,
  }) {
    final normalizedDescription = description.trim();
    final candidates = transactions.where((transaction) {
      final sameDay = transaction.date.year == date.year &&
          transaction.date.month == date.month &&
          transaction.date.day == date.day;
      return transaction.type == type &&
          transaction.amount == amount &&
          transaction.description.trim() == normalizedDescription &&
          transaction.categoryId == categoryId.toString() &&
          sameDay;
    }).toList()
      ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    return candidates.isEmpty ? null : candidates.first.id;
  }

  List<TransactionModel> get filteredTransactions {
    if (movementFilter == "ingreso") {
      return transactions.where((t) => t.type == "ingreso").toList();
    }
    if (movementFilter == "gasto") {
      return transactions.where((t) => t.type == "gasto").toList();
    }
    return transactions;
  }

  List<TransactionModel> get visibleTransactions {
    if (_showAllMovements || filteredTransactions.length <= 4) {
      return filteredTransactions;
    }
    return filteredTransactions.take(4).toList();
  }

  List<TransactionModel> get visibleCurrentTransactions =>
      visibleTransactions.where((t) => !t.isFutureMovement).toList();

  List<TransactionModel> get futureTransactions =>
      filteredTransactions.where((t) => t.isFutureMovement).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  Map<String, double> getGastosPorCategoria() {
    Map<String, double> data = {};

    for (var t in transactions) {
      if (t.type == "gasto") {
        String categoria = getCategoryName(int.tryParse(t.categoryId) ?? 0);

        data[categoria] =
            (data[categoria] ?? 0) + _convertToBase(t.amount, _transactionCurrency(t));
      }
    }

    return data;
  }

  Map<String, double> getMovimientosPorCategoria(String tipo) {
    Map<String, double> data = {};

    for (var t in transactions) {
      if (t.type == tipo) {
        String categoria = getCategoryName(
          int.tryParse(
                t.categoryId,
              ) ??
              0,
        );

        data[categoria] =
            (data[categoria] ?? 0) + _convertToBase(t.amount, _transactionCurrency(t));
      }
    }

    final sorted = data.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    return Map.fromEntries(sorted);
  }

  Color getCategoryColor(String categoria) {
    String c = categoria.toLowerCase();

    if (c.contains("comida")) return Colors.orange;
    if (c.contains("mercado")) return Colors.deepOrange;
    if (c.contains("transporte")) return Colors.blue;
    if (c.contains("salud")) return Colors.red;
    if (c.contains("ahorro")) return Colors.green;
    if (c.contains("trabajo")) return Colors.indigo;
    if (c.contains("educacion")) return Colors.purple;

    return const Color(0xFF00C853);
  }

  @override
  Widget build(BuildContext context) {
    final metas = context.watch<AuthProvider>().metas;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF064E3B);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 4),

      // APPBAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            Colors.transparent, // Fondo transparente para mayor fluidez
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            // Logo o Icono de la marca con un degradado sutil
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF00E676)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(
                    12), // Bordes mas redondeados son tendencia
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C853).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Finara", // Nombre de la App
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1B4332),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  "Mi Perfil", // Subtitulo indicativo
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      //DRAWER (MENU)
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // HEADER PERSONALIZADO
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF064E3B),
              ),
              currentAccountPicture: Stack(
                clipBehavior: Clip.none,
                children: [
                  _profileAvatar(radius: 36, iconSize: 38, bordered: true),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: AnimatedContainer(
                        // Pequena animacion al tocar
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(
                            6), // Un poquito mÃ¡s grande para el dedo
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Icon(
                            Icons
                                .camera_alt, // Camera_alt se entiende mejor que edit
                            color: Colors.white,
                            size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              accountName: Text(
                name.isEmpty ? "Cargando..." : name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white),
              ),
              accountEmail: Text(
                email.isEmpty ? "Cargando..." : email,
                style: const TextStyle(color: Colors.white70),
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("CONFIGURACION",
                        style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                  ),

                  // MODO OSCURO MEJORADO
                  _buildDrawerItem(
                    icon: isDark ? Icons.light_mode : Icons.dark_mode,
                    title: isDark ? "Modo claro" : "Modo oscuro",
                    color: Colors.orange,
                    onTap: () => context.read<ThemeProvider>().toggleTheme(),
                  ),

                  _buildDrawerItem(
                    icon: Icons.currency_exchange_rounded,
                    title: "Moneda",
                    subtitle: _currencyLabel(baseCurrency),
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(context);
                      _selectBaseCurrency();
                    },
                  ),

                  _buildDrawerItem(
                    icon: Icons.picture_as_pdf_rounded,
                    title: "Exportar PDF",
                    subtitle: "Movimientos y balance",
                    color: const Color(0xFF2563EB),
                    onTap: () async {
                      Navigator.pop(context);
                      await _exportMovementsPdf();
                    },
                  ),

                  // IDIOMA MEJORADO
                  Consumer<LanguageProvider>(
                    builder: (context, langProvider, child) {
                      return _buildDrawerItem(
                        icon: Icons.translate,
                        title: "Idioma de la App",
                        subtitle: langProvider.currentLanguageName,
                        color: const Color(0xFF00C853),
                        onTap: () => _showLanguagePicker(context, langProvider),
                      );
                    },
                  ),

                  _buildDrawerItem(
                    icon: Icons.badge_rounded,
                    title: "Informacion personal",
                    subtitle:
                        username.isEmpty ? "Completa tu perfil" : "@$username",
                    color: const Color(0xFFE1306C),
                    onTap: () {
                      Navigator.pop(context);
                      _showProfileInfoSheet();
                    },
                  ),

                  _buildDrawerItem(
                    icon: Icons.support_agent_rounded,
                    title: "Soporte",
                    subtitle: "Ayuda y contacto",
                    color: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.pop(context);
                      _showSupportSheet();
                    },
                  ),
                ],
              ),
            ),

            // BOTÃ“N DE CERRAR SESIÃ“N
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.red.withOpacity(0.1),
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const TranslatedText("Cerrar sesion",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () async {
                  final auth = context.read<AuthProvider>();

                  await auth.logout();

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),

      //BODY CRUD
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                //PERFIL
                Row(
                  children: [
                    _profileAvatar(radius: 30, iconSize: 30),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? "Cargando..." : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            email.isEmpty ? "Cargando..." : email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // TARJETA DE BALANCE MEJORADA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24), // Un poco más de aire
                  decoration: BoxDecoration(
                    // Un degradado sutil lo hace ver más "Premium"
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                          : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Balance Total",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF1B4332).withOpacity(0.7),
                              fontSize: 16,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF1B4332).withOpacity(0.3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatCurrency(getBalance()),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1B4332),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Un pequeño indicador extra le da el toque final
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Actualizado hace un momento",
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF1B4332),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //SECCIÓN METAS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Metas de ahorro",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: _crearMetaResponsive,
                      icon: const Icon(Icons.add, color: Color(0xFF00C853)),
                    )
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: (MediaQuery.of(context).size.height * 0.38)
                      .clamp(355.0, 420.0)
                      .toDouble(),
                  child: metas.isEmpty
                      ? const Center(child: Text("No hay metas aún"))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: metas.length,
                          itemBuilder: (context, index) {
                            final meta = metas[index];

                            final progress =
                                (meta.progreso.clamp(0.0, 1.0) as num)
                                    .toDouble();
                            final remaining =
                                (meta.montoMeta - meta.montoActual)
                                    .clamp(0, double.infinity)
                                    .toDouble();

                            return Container(
                              width: 286,
                              margin: const EdgeInsets.only(right: 14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF10231E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : const Color(0xFFE2E8F0),
                                ),
                                boxShadow: isDark
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: const Color(0xFF064E3B)
                                              .withOpacity(0.08),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        )
                                      ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 132,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (meta.imageData != null &&
                                              meta.imageData!.isNotEmpty)
                                            Image.memory(
                                              base64Decode(meta.imageData!),
                                              fit: BoxFit.cover,
                                            )
                                          else
                                            Container(
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Color(0xFF064E3B),
                                                    Color(0xFF10B981),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.black.withOpacity(0.05),
                                                  Colors.black.withOpacity(0.48),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 14,
                                            right: 14,
                                            bottom: 12,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    meta.nombre,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 9,
                                                    vertical: 5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.18),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                    border: Border.all(
                                                      color: Colors.white24,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    "${meta.porcentaje.toStringAsFixed(0)}%",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: LinearProgressIndicator(
                                                minHeight: 9,
                                                value: progress,
                                                backgroundColor: isDark
                                                    ? Colors.white10
                                                    : const Color(0xFFE2E8F0),
                                                color:
                                                    const Color(0xFF10B981),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _goalMetric(
                                                    "Llevas",
                                                    formatCurrency(
                                                        meta.montoActual),
                                                    isDark,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: _goalMetric(
                                                    "Faltan",
                                                    formatCurrency(remaining),
                                                    isDark,
                                                    danger: true,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            Row(
                                              children: [
                                                Icon(Icons.schedule_rounded,
                                                    size: 15,
                                                    color: isDark
                                                        ? Colors.white54
                                                        : Colors.grey),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                  child: Text(
                                                    "${meta.mesesRestantes} meses restantes",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? Colors.white60
                                                          : Colors.grey[600],
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                _goalAction(
                                                  Icons.add_rounded,
                                                  const Color(0xFF10B981),
                                                  () => _agregarMontoMeta(index),
                                                ),
                                                _goalAction(
                                                  Icons.edit_rounded,
                                                  const Color(0xFF2563EB),
                                                  () =>
                                                      _editarMetaResponsive(index),
                                                ),
                                                _goalAction(
                                                  Icons.delete_outline_rounded,
                                                  const Color(0xFFEF4444),
                                                  () => _eliminarMeta(index),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 20),

                //TÍTULO Y BOTÓN AGREGAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const TranslatedText(
                      "Movimientos",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () => showForm(),
                      icon: const Icon(Icons.add, color: Color(0xFF00C853)),
                      label: const TranslatedText("Agregar",
                          style: TextStyle(color: Color(0xFF00C853))),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _buildChartsPager(isDark),

                _buildMovementFilters(isDark),
                const SizedBox(height: 14),

                //LISTA DE TRANSACCIONES
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleCurrentTransactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final t = visibleCurrentTransactions[index];
                    final bool isIngreso = t.type == "ingreso";
                    final bool isFuture = t.isFutureMovement;
                    final categoryName =
                        getCategoryName(int.tryParse(t.categoryId) ?? 0);
                    final catData = _getCategoryData(categoryName);
                    return Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isFuture
                            ? (isDark
                                ? const Color(0xFF172554)
                                : const Color(0xFFEFF6FF))
                            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: isFuture
                            ? Border.all(color: const Color(0xFF3B82F6))
                            : null,
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10)
                              ],
                      ),
                      child: Row(
                        children: [
                          //ICON SEGÚN LA IMAGEN
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: catData['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(catData['icon'],
                                color: catData['color'], size: 24),
                          ),
                          const SizedBox(width: 15),

                          //DESCRIPCIÓN Y FECHA
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currencyLabel(_transactionCurrency(t)),
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t.description,
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat("dd/MM/yyyy").format(t.date),
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12),
                                ),
                                if (isFuture) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      "Próximo movimiento",
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          //MONTO Y ACCIONES
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${isIngreso ? '+' : '-'} ${formatCurrency(t.amount, _transactionCurrency(t))}",
                                style: TextStyle(
                                  color: isIngreso
                                      ? Colors.green
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => showForm(edit: t),
                                    child: const Icon(Icons.edit_note,
                                        size: 20, color: Colors.blueGrey),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => confirmDelete(t),
                                    child: const Icon(Icons.delete_outline,
                                        size: 20, color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (filteredTransactions.length > 4) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(
                          () => _showAllMovements = !_showAllMovements),
                      icon: Icon(_showAllMovements
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded),
                      label: Text(_showAllMovements
                          ? "Ver menos movimientos"
                          : "Ver mas movimientos"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF064E3B),
                        side: const BorderSide(color: Color(0xFF10B981)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
                if (futureTransactions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Gastos e ingresos futuros",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "${futureTransactions.length}",
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: futureTransactions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final t = futureTransactions[index];
                      final isIngreso = t.type == "ingreso";
                      final categoryName =
                          getCategoryName(int.tryParse(t.categoryId) ?? 0);
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF172554)
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(18),
                          border:
                              Border.all(color: const Color(0xFF3B82F6)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6)
                                    .withOpacity(0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isIngreso
                                    ? Icons.trending_up_rounded
                                    : Icons.event_available_rounded,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    categoryName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${_currencyLabel(_transactionCurrency(t))} • ${DateFormat("dd/MM/yyyy").format(t.date)}",
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t.description,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${isIngreso ? '+' : '-'} ${formatCurrency(t.amount, _transactionCurrency(t))}",
                                  style: TextStyle(
                                    color: isIngreso
                                        ? Colors.green
                                        : Colors.redAccent,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => showForm(edit: t),
                                      icon: const Icon(Icons.edit_note,
                                          color: Colors.blueGrey),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => confirmDelete(t),
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsivePieChart(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isNarrow = width < 380;
        final chartSize =
            (width * (isNarrow ? 0.62 : 0.5)).clamp(160.0, 220.0).toDouble();
        final radius = (chartSize * 0.30).clamp(48.0, 66.0).toDouble();
        final centerRadius =
            (chartSize * 0.25).clamp(38.0, 55.0).toDouble();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isNarrow ? 16 : 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    )
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Resumen financiero",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: chartSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: centerRadius,
                        sectionsSpace: 4,
                        centerSpaceColor:
                            isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        sections: [
                          PieChartSectionData(
                            value: getTotalIngresos(),
                            color: Colors.green,
                            radius: radius,
                            title: getTotalGeneral() == 0
                                ? "0%"
                                : "${((getTotalIngresos() / getTotalGeneral()) * 100).toStringAsFixed(1)}%",
                            titleStyle: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isNarrow ? 12 : 15,
                            ),
                          ),
                          PieChartSectionData(
                            value: getTotalGastos(),
                            color: Colors.redAccent,
                            radius: radius,
                            title: getTotalGeneral() == 0
                                ? "0%"
                                : "${((getTotalGastos() / getTotalGeneral()) * 100).toStringAsFixed(1)}%",
                            titleStyle: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isNarrow ? 12 : 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Balance",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: centerRadius * 1.9,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatCurrency(getBalance()),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 10,
                children: [
                  _chartLegend(
                    Colors.green,
                    "Ingresos: ${formatCurrency(getTotalIngresos())}",
                  ),
                  _chartLegend(
                    Colors.redAccent,
                    "Gastos: ${formatCurrency(getTotalGastos())}",
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _goalMetric(
    String label,
    String value,
    bool isDark, {
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalAction(IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildChartsPager(bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 390,
          child: PageView(
            onPageChanged: (page) {
              setState(() => activeChartPage = page);
            },
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildResponsivePieChart(isDark),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    _buildChartTypeToggle(isDark),
                    const SizedBox(height: 14),
                    Expanded(child: _buildResponsiveBarChart(isDark)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pagerDot(activeChartPage == 0),
            const SizedBox(width: 6),
            _pagerDot(activeChartPage == 1),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _pagerDot(bool active) {
    return Container(
      width: active ? 18 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _buildChartTypeToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey[200],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedChartType = "ingreso"),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedChartType == "ingreso"
                      ? const Color(0xFF00C853)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    "Ingresos",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedChartType = "gasto"),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedChartType == "gasto"
                      ? Colors.redAccent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    "Gastos",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveBarChart(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final data = getMovimientosPorCategoria(selectedChartType).entries.toList();
        final chartWidth = data.isEmpty
            ? constraints.maxWidth
            : (data.length * 74.0)
                .clamp(constraints.maxWidth, 900.0)
                .toDouble();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            height: constraints.maxWidth < 380 ? 280 : 320,
            child: data.isEmpty
                ? const Center(child: Text("No hay datos para graficar"))
                : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: chartWidth,
                          child: BarChart(
                            BarChartData(
                              borderData: FlBorderData(show: false),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  tooltipRoundedRadius: 14,
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                    final item = data[group.x];
                                    return BarTooltipItem(
                                      "${item.key}\n${formatCurrency(item.value)}",
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              alignment: BarChartAlignment.spaceAround,
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 44,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 44,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= data.length) {
                                        return const SizedBox();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: SizedBox(
                                          width: 64,
                                          child: Text(
                                            data[index].key,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              barGroups: data.asMap().entries.map((entry) {
                                final item = entry.value;
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: item.value,
                                      color: getCategoryColor(item.key),
                                      width: 22,
                                      borderRadius: BorderRadius.circular(8),
                                    )
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
          ),
        );
      },
    );
  }

  Widget _buildMovementFilters(bool isDark) {
    final items = [
      ("todos", "Todos", Icons.list_rounded, const Color(0xFF10B981)),
      ("ingreso", "Ingresos", Icons.trending_up_rounded, const Color(0xFF059669)),
      ("gasto", "Gastos", Icons.trending_down_rounded, const Color(0xFFEF4444)),
    ];

    return Row(
      children: items.map((item) {
        final selected = movementFilter == item.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() {
                movementFilter = item.$1;
                _showAllMovements = false;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? item.$4
                      : (isDark ? const Color(0xFF10231E) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? item.$4
                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: item.$4.withOpacity(0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.$3,
                        color: selected ? Colors.white : item.$4, size: 20),
                    const SizedBox(height: 5),
                    FittedBox(
                      child: Text(
                        item.$2,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155)),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void showForm({TransactionModel? edit}) async {
    await loadCategories();
    List<CategoryModel> localCategories = List.from(categories);
    final today = DateTime.now();
    final selectedInitialDate = edit?.date ?? today;
    final dateController = TextEditingController(
        text: edit != null
            ? DateFormat("MM/dd/yyyy").format(selectedInitialDate)
            : DateFormat("MM/dd/yyyy").format(today));

    final desc = TextEditingController(text: edit?.description);
    final amount = TextEditingController(
      text: edit != null ? _formatInputAmount(edit.amount) : "",
    );
    String type = edit?.type ?? "gasto";
    int? selectedCategoryId = int.tryParse(edit?.categoryId ?? "");
    String selectedMovementCurrency = (edit?.currency.trim().isNotEmpty ?? false)
        ? edit!.currency.toUpperCase()
        : _categoryCurrencyById(selectedCategoryId);
    bool allowFutureMovement = edit?.isFutureMovement ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        bool isLoadingDialog = false;
        bool showValidationErrors = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

              final double amountValue = _parseMoney(amount.text);

            final filteredCategories =
                localCategories.where((c) => c.type == type).toList();

            if (filteredCategories.isNotEmpty) {
              if (selectedCategoryId == null ||
                  !filteredCategories
                      .any((c) => int.parse(c.id) == selectedCategoryId)) {
                selectedCategoryId = int.parse(filteredCategories.first.id);
                if (edit == null) {
                  selectedMovementCurrency =
                      _categoryCurrencyById(selectedCategoryId);
                }
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  //BARRA SUPERIOR (Indicador de arrastre)
                  const SizedBox(height: 12),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TÃTULO
                          Center(
                            child: Text(
                              edit == null
                                  ? "Nuevo Movimiento"
                                  : "Editar Movimiento",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ), // Center
                          ),

                          const SizedBox(height: 25),

                          // SELECTOR GASTO / INGRESO
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.grey[100],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                _buildTypeButton(
                                    "gasto",
                                    type,
                                    (v) => setStateDialog(() {
                                          type = v;
                                          selectedCategoryId = null;
                                        }),
                                    isDark),
                                _buildTypeButton(
                                    "ingreso",
                                    type,
                                    (v) => setStateDialog(() {
                                          type = v;
                                          selectedCategoryId = null;
                                        }),
                                    isDark),
                              ],
                            ), // Row
                          ),

                          const SizedBox(height: 35),

                          // CAMPO MONTO

                          const Center(
                            child: TranslatedText(
                              "Ingresar monto",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          TextField(
                            controller: amount,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CurrencyInputFormatter(),
                            ],
                            style: const TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF064E3B),
                            ),
                            // DESPUÉS
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.attach_money,
                                  size: 35, color: Color(0xFF064E3B)),
                              hintText: "0.00",
                              border: InputBorder.none,
                              errorText: (showValidationErrors &&
                                    amount.text.trim().isNotEmpty &&
                                      amountValue == 0)
                                  ? "Ingresa un monto válido"
                                  : null,
                            ),
                          ),

                          const SizedBox(height: 25),

                          // SELECTOR CATEGORA
                          const TranslatedText("Categoria",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 10),

                          // 1. Btn para crear nueva
                          TextButton(
                            onPressed: () async {
                              String? nueva =
                                  await _mostrarDialogoCategoriaBonita();

                              if (nueva != null) {
                                nueva = nueva.trim();
                              }

                              if (nueva != null && nueva.isNotEmpty) {
                                final nuevaMoneda =
                                    await _showCurrencyPicker(baseCurrency);
                                if (nuevaMoneda == null) return;

                                // Validación local: usamos ignoreCase para mayor seguridad
                                if (localCategories.any((c) =>
                                    c.type == type &&
                                    c.name.trim().toLowerCase() ==
                                        nueva!.toLowerCase())) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Esa categoria ya existe"),
                                    ),
                                  );
                                  return;
                                }

                                final auth = context.read<AuthProvider>();
                                bool success = await ApiService.createCategory(
                                    auth.token!, nueva, type, nuevaMoneda);

                                if (!success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "No se pudo crear la categoría. Intenta de nuevo."),
                                    ),
                                  );
                                  return;
                                }

                                await loadCategories(); // Recarga la lista global 'categories'

                                setStateDialog(() {
                                  // ACTUALIZACIÓN CRÍTICA:
                                  // 1. Sincronizamos la lista local con la global recién cargada
                                  localCategories = List.from(categories);

                                  // 2. Filtramos inmediatamente para que el Dropdown vea el cambio
                                  final filtered = localCategories
                                      .where((c) => c.type == type)
                                      .toList();

                                  if (filtered.isNotEmpty) {
                                    // 3. Intentamos encontrar la que acabamos de crear por nombre
                                    // (Es más seguro que .last si la lista venga ordenada del servidor)
                                    final creada = filtered.firstWhere(
                                      (c) =>
                                          c.name.trim().toLowerCase() ==
                                          nueva!.toLowerCase(),
                                      orElse: () => filtered.last,
                                    );
                                    _saveCategoryCurrency(
                                        creada.id, nuevaMoneda);
                                    selectedCategoryId = int.parse(creada.id);
                                  }
                                });

                                _showTopNotice(
                                  "Categoría creada correctamente",
                                  isError: false,
                                  icon: Icons.check_circle_rounded,
                                );
                              }
                            },
                            child: const Text("Agregar categoria",
                                style: TextStyle(color: Colors.green)),
                          ),

// 2. Fila con Dropdown + Editar + Eliminar
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.black12
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(15),
                                    border:
                                        Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: DropdownButton<int>(
                                    value: selectedCategoryId,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    // IMPORTANTE: AsegÃºrate de que filteredCategories se re-calcule
                                    // antes de este punto en el build del diÃ¡logo.
                                    items: localCategories
                                        .where((c) =>
                                            c.type ==
                                            type) // Filtramos aquÃ­ directamente para evitar desfases
                                        .map((cat) {
                                      return DropdownMenuItem<int>(
                                        value: int.parse(cat.id),
                                        child: Text(cat.name),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      setStateDialog(() {
                                        selectedCategoryId = v;
                                        if (edit == null && v != null) {
                                          selectedMovementCurrency =
                                              _categoryCurrencyById(v);
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                              if (selectedCategoryId != null) ...[
                                // BOTÃ“N EDITAR
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Colors.blueAccent),
                                  onPressed: () async {
                                    // Buscamos en localCategories directamente
                                    final catActual =
                                        localCategories.firstWhere(
                                      (c) =>
                                          int.parse(c.id) == selectedCategoryId,
                                    );

                                    String? nuevoNombre =
                                        await _mostrarDialogoCategoriaBonita(
                                      valorInicial: catActual.name,
                                    );

                                    if (nuevoNombre != null &&
                                        nuevoNombre.isNotEmpty) {
                                      if (localCategories.any((c) =>
                                          c.id != catActual.id &&
                                          c.type == type &&
                                          c.name.toLowerCase() ==
                                              nuevoNombre.toLowerCase())) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Esa categoría ya existe"),
                                          ),
                                        );
                                        return;
                                      }

                                      final auth = context.read<AuthProvider>();
                                      bool success =
                                          await ApiService.updateCategory(
                                        auth.token!,
                                        selectedCategoryId!,
                                        nuevoNombre,
                                        type,
                                        catActual.currency,
                                      );
                                      if (success) {
                                        await loadCategories();
                                        setStateDialog(() {
                                          localCategories =
                                              List.from(categories);
                                        });
                                        _showTopNotice(
                                          "Categoría actualizada correctamente",
                                          isError: false,
                                          icon: Icons.check_circle_rounded,
                                        );
                                      } else {
                                        _showTopNotice(
                                          "Error al actualizar la categoría",
                                          isError: true,
                                          icon: Icons.error_outline_rounded,
                                        );
                                      }
                                    }
                                  },
                                ),
                                // BOTÃ“N ELIMINAR
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () async {
                                    bool? confirmar = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text(
                                            "¿Eliminar categoría?"),
                                        content: const Text(
                                            "Esta acción no se puede deshacer."),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text("Cancelar"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text("Eliminar",
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmar == true) {
                                      final auth = context.read<AuthProvider>();
                                      bool success =
                                          await ApiService.deleteCategory(
                                        auth.token!,
                                        selectedCategoryId!,
                                      );
                                      if (success) {
                                        await loadCategories();
                                        setStateDialog(() {
                                          localCategories =
                                              List.from(categories);
                                          selectedCategoryId =
                                              null; // Reset de selección
                                        });
                                        _showTopNotice(
                                          "Categoría eliminada correctamente",
                                          isError: false,
                                          icon: Icons.check_circle_rounded,
                                        );
                                      } else {
                                        _showTopNotice(
                                          "Error al eliminar la categoría",
                                          isError: true,
                                          icon: Icons.error_outline_rounded,
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 25),

                          const TranslatedText("Moneda del movimiento",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () async {
                              final selected = await _showCurrencyPicker(
                                selectedMovementCurrency,
                              );
                              if (selected == null) return;
                              setStateDialog(() {
                                selectedMovementCurrency = selected;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color:
                                    isDark ? Colors.black12 : Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.currency_exchange_rounded,
                                      color: Colors.green, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _currencyLabel(selectedMovementCurrency),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          //AQUÃ REGRESA LA FECHA
                          InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () {
                              setStateDialog(() {
                                allowFutureMovement = !allowFutureMovement;
                                final parsed = DateFormat("MM/dd/yyyy")
                                    .tryParse(dateController.text);
                                final todayOnly = DateTime(
                                    today.year, today.month, today.day);
                                if (!allowFutureMovement &&
                                    parsed != null &&
                                    parsed.isAfter(todayOnly)) {
                                  dateController.text =
                                      DateFormat("MM/dd/yyyy").format(today);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: allowFutureMovement
                                      ? [
                                          const Color(0xFF2563EB),
                                          const Color(0xFF10B981),
                                        ]
                                      : [
                                          isDark
                                              ? const Color(0xFF17231F)
                                              : const Color(0xFFF8FAFC),
                                          isDark
                                              ? const Color(0xFF10231E)
                                              : const Color(0xFFEFF6FF),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: allowFutureMovement
                                      ? Colors.transparent
                                      : const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: allowFutureMovement
                                          ? Colors.white.withOpacity(0.18)
                                          : const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      type == "ingreso"
                                          ? Icons.trending_up_rounded
                                          : Icons.event_available_rounded,
                                      color: allowFutureMovement
                                          ? Colors.white
                                          : const Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          type == "ingreso"
                                              ? "Ingresos futuros"
                                              : "Gastos futuros",
                                          style: TextStyle(
                                            color: allowFutureMovement
                                                ? Colors.white
                                                : null,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          allowFutureMovement
                                              ? "Fechas futuras habilitadas"
                                              : "Toca para permitir fechas futuras",
                                          style: TextStyle(
                                            color: allowFutureMovement
                                                ? Colors.white70
                                                : Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    allowFutureMovement
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: allowFutureMovement
                                        ? Colors.white
                                        : const Color(0xFF2563EB),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const TranslatedText("Fecha",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () async {
                              final parsedDate = DateFormat("MM/dd/yyyy")
                                  .tryParse(dateController.text);
                              final maxDate = allowFutureMovement
                                  ? DateTime(2101)
                                  : DateTime(
                                      today.year,
                                      today.month,
                                      today.day,
                                    );
                              final safeInitialDate = (parsedDate != null &&
                                      !parsedDate.isAfter(maxDate))
                                  ? parsedDate
                                  : maxDate;
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: safeInitialDate,
                                firstDate: DateTime(2000),
                                lastDate: maxDate,
                              );
                              if (picked != null) {
                                setStateDialog(() => dateController.text =
                                    DateFormat("MM/dd/yyyy").format(picked));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color:
                                    isDark ? Colors.black12 : Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      color: Colors.green, size: 20),
                                  const SizedBox(width: 12),
                                  Text("${dateController.text}"),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          //Notas
                          const TranslatedText("Notas",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: desc,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: Colors.green,
                            // DESPUÉS
                            decoration: InputDecoration(
                              hintText: "Escribe una nota...",
                              hintStyle: TextStyle(
                                color:
                                    isDark ? Colors.white38 : Colors.grey[500],
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0B1F1B)
                                  : Colors.grey[50],
                              errorText: (showValidationErrors &&
                                      desc.text.trim().isEmpty)
                                  ? "La descripción es obligatoria"
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: (showValidationErrors &&
                                          desc.text.trim().isEmpty)
                                      ? Colors.redAccent
                                      : isDark
                                          ? Colors.white.withOpacity(0.12)
                                          : Colors.grey[200]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: (showValidationErrors &&
                                          desc.text.trim().isEmpty)
                                      ? Colors.redAccent
                                      : isDark
                                          ? Colors.white.withOpacity(0.12)
                                          : Colors.grey[200]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: (showValidationErrors &&
                                          desc.text.trim().isEmpty)
                                      ? Colors.redAccent
                                      : Colors.green,
                                  width: 1.6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),
                          // BOTÃ“N GUARDAR

                          //(SizedBox despuÃ©s del TextField de Notas)
                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C853),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                elevation: 0,
                              ),
                              onPressed: isLoadingDialog
                                  ? null
                                  : () async {
                                      // 1. Validar que el monto no estÃ© vacÃ­o o sea 0
                                      setStateDialog(
                                          () => showValidationErrors = true);

                                        double montoFinal = _parseMoney(amount.text);
                                      DateTime fechaFinal =
                                          DateFormat("MM/dd/yyyy")
                                              .parse(dateController.text);

                                      // Validar todo junto
                                      if (selectedCategoryId == null ||
                                          montoFinal <= 0 ||
                                          desc.text.trim().isEmpty) {
                                        _showTopNotice(
                                          "Completa monto, categoria y descripcion",
                                          icon: Icons.error_outline_rounded,
                                        );
                                        return;
                                      }

                                      int categoryId = selectedCategoryId!;

                                      if (montoFinal <= 0) {
                                        _showTopNotice(
                                          "Por favor ingresa un monto valido",
                                          icon: Icons.error_outline_rounded,
                                        );
                                        return;
                                      }

                                      if (desc.text.trim().isEmpty) {
                                        _showTopNotice(
                                          "Por favor ingresa una descripcion",
                                          icon: Icons.error_outline_rounded,
                                        );
                                        return;
                                      }

                                      setStateDialog(
                                          () => isLoadingDialog = true);

                                      final auth = context.read<AuthProvider>();

                                      bool success;
                                      if (edit == null) {
                                        // ES NUEVO
                                        success =
                                            await ApiService.createTransaction(
                                          auth.token!,
                                          type,
                                          montoFinal,
                                          desc.text,
                                          categoryId,
                                          fechaFinal,
                                          selectedMovementCurrency,
                                        );
                                        if (type == "ingreso") {
                                          context
                                              .read<AuthProvider>()
                                              .actualizarMetasConIngreso(
                                                  montoFinal);
                                        }
                                      } else {
                                        // ES EDICIÃ“N
                                        success =
                                            await ApiService.updateTransaction(
                                          auth.token!,
                                          edit.id!,
                                          type,
                                          montoFinal,
                                          desc.text,
                                          categoryId,
                                          fechaFinal,
                                          selectedMovementCurrency,
                                        );
                                      }

                                      if (success) {
                                        if (!mounted) return;
                                        Navigator.pop(
                                            context); // Cierra el formulario
                                        await loadTransactions(); // Recarga la lista principal
                                        final savedTransactionId = edit?.id ??
                                            _findSavedTransactionId(
                                              type: type,
                                              amount: montoFinal,
                                              description: desc.text,
                                              categoryId: categoryId,
                                              date: fechaFinal,
                                            );
                                        if (savedTransactionId != null) {
                                          await _saveTransactionCurrency(
                                            savedTransactionId,
                                            selectedMovementCurrency,
                                          );
                                          setState(() {
                                            for (final transaction
                                                in transactions) {
                                              if (transaction.id ==
                                                  savedTransactionId) {
                                                transaction.currency =
                                                    selectedMovementCurrency;
                                              }
                                            }
                                          });
                                        }
                                        _showTopNotice(
                                          edit == null
                                              ? "Movimiento creado correctamente"
                                              : "Movimiento actualizado correctamente",
                                          isError: false,
                                          icon: Icons.check_circle_rounded,
                                        );
                                      } else {
                                        setStateDialog(
                                            () => isLoadingDialog = false);
                                        _showTopNotice(
                                          "Error al guardar en el servidor",
                                          icon: Icons.error_outline_rounded,
                                        );
                                      }
                                    },
                              child: isLoadingDialog
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : TranslatedText(
                                      edit == null
                                          ? "Guardar Movimiento"
                                          : "Actualizar Movimiento",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          // DropdownButton
                        ], // Cierre de children
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// Helper para los botones de tipo
  Widget _buildTypeButton(
      String title, String current, Function(String) onTap, bool isDark) {
    bool isSelected = title == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF064E3B) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 4)
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title[0].toUpperCase() + title.substring(1),
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.green)
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void confirmDelete(TransactionModel t) {
    showDialog(
      context: context,
      builder: (_) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text("¿Eliminar movimiento?",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Se eliminará '${t.description}'"),
                  const SizedBox(height: 8),
                  Text("Monto: ${formatCurrency(t.amount, _transactionCurrency(t))}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: const Text("Cancelar",
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          final auth = context.read<AuthProvider>();
                          final token = auth.token;
                          if (token == null || token.isEmpty || t.id == null) {
                            _showTopNotice(
                              "No se pudo eliminar el movimiento",
                              icon: Icons.error_outline_rounded,
                            );
                            return;
                          }

                          setStateDialog(() => isDeleting = true);
                          final success =
                              await ApiService.deleteTransaction(token, t.id!);
                          if (!mounted) return;
                          Navigator.pop(context);

                          if (success) {
                            await loadTransactions();
                            _showTopNotice(
                              "Movimiento eliminado correctamente",
                              isError: false,
                              icon: Icons.check_circle_rounded,
                            );
                          } else {
                            _showTopNotice(
                              "Error al eliminar el movimiento",
                              icon: Icons.error_outline_rounded,
                            );
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text("Eliminar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _mostrarDialogoNuevaCategoria({String? valorInicial}) async {
    TextEditingController controller = TextEditingController();
    controller.text = valorInicial ?? '';

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const TranslatedText("Nueva categoría"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Ej: Transporte, Comida...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const TranslatedText("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, controller.text);
            },
            child: const TranslatedText("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<String?> _mostrarDialogoCategoriaBonita({String? valorInicial}) async {
    final controller = TextEditingController(text: valorInicial ?? '');
    bool showError = false;

    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final hasError = showError && controller.text.trim().isEmpty;

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF10231E) : Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.category_rounded,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          valorInicial == null
                              ? "Nueva categoria"
                              : "Editar categoria",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Organiza tus movimientos con nombres claros y faciles de reconocer.",
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setStateDialog(() {}),
                    decoration: InputDecoration(
                      labelText: "Nombre de categoria",
                      hintText: "Ej: Transporte, Comida, Nomina",
                      prefixIcon: const Icon(
                        Icons.label_outline_rounded,
                        color: Color(0xFF10B981),
                      ),
                      filled: true,
                      fillColor:
                          isDark ? Colors.black12 : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: hasError
                              ? Colors.redAccent
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: hasError
                              ? Colors.redAccent
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: hasError
                              ? Colors.redAccent
                              : const Color(0xFF10B981),
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 8),
                    const Text(
                      "Este campo es obligatorio.",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text("Cancelar"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setStateDialog(() => showError = true);
                            if (controller.text.trim().isEmpty) return;
                            Navigator.pop(context, controller.text.trim());
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Guardar",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Constructor de items para el menÃº
  Widget _buildDrawerItem(
      {required IconData icon,
      required String title,
      String? subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color),
      ),
      title: TranslatedText(title,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

// El Modal de Idioma pero llamado desde afuera
  void _showLanguagePicker(
      BuildContext context, LanguageProvider langProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          mainAxisSize:
              MainAxisSize.min, // Hace que el modal solo ocupe lo necesario
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: TranslatedText("Selecciona Idioma",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: langProvider.supportedLanguages.length,
                itemBuilder: (context, index) {
                  String key =
                      langProvider.supportedLanguages.keys.elementAt(index);
                  String name = langProvider.supportedLanguages[key]!;
                  return ListTile(
                    title: Text(name),
                    trailing: langProvider.currentLanguage == key
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      langProvider.setLanguage(key);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProfileInfoSheet() {
    final usernameController = TextEditingController(text: username);
    final ageController = TextEditingController(text: age);
    final descriptionController = TextEditingController(text: description);
    final phoneController = TextEditingController(text: phone);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 18,
              bottom: MediaQuery.of(context).viewInsets.bottom + 22,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF10231E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _profileAvatar(radius: 34, iconSize: 34),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? "Mi perfil" : name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              usernameController.text.trim().isEmpty
                                  ? "Agrega tu usuario"
                                  : "@${usernameController.text.trim()}",
                              style: const TextStyle(
                                color: Color(0xFFE1306C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _profileInput(
                    controller: usernameController,
                    label: "Nombre de usuario",
                    hint: "ej: alex_finara",
                    icon: Icons.alternate_email_rounded,
                  ),
                  _profileInput(
                    controller: ageController,
                    label: "Edad",
                    hint: "ej: 24",
                    icon: Icons.cake_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  _profileInput(
                    controller: phoneController,
                    label: "Telefono",
                    hint: "ej: +57 300 000 0000",
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  _profileInput(
                    controller: descriptionController,
                    label: "Descripcion",
                    hint: "Cuentanos algo sobre ti",
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheetState(() => isSaving = true);
                              final auth = context.read<AuthProvider>();
                              final result = await ApiService.updateProfileInfo(
                                auth.token!,
                                username: usernameController.text,
                                age: ageController.text,
                                description: descriptionController.text,
                                phone: phoneController.text,
                              );

                              if (!mounted) return;

                              if (result != null) {
                                setState(() {
                                  username = result["username"] ?? "";
                                  age = result["age"]?.toString() ?? "";
                                  description = result["description"] ?? "";
                                  phone = result["phone"] ?? "";
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Informacion actualizada"),
                                  ),
                                );
                              } else {
                                setSheetState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("No se pudo guardar"),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE1306C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Guardar informacion",
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _profileInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF0B1F1B) : const Color(0xFFF8FAFC);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final hintColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        cursorColor: const Color(0xFFE1306C),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
          hintStyle: TextStyle(color: hintColor),
          prefixIcon: Icon(icon, color: const Color(0xFFE1306C)),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE1306C), width: 1.6),
          ),
        ),
      ),
    );
  }

  void _showSupportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF10231E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: Color(0xFF2563EB), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                "Soporte Finara",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                "Estamos listos para ayudarte con tu cuenta, movimientos, metas o dudas de la app.",
              ),
              const SizedBox(height: 18),
              _supportTile(Icons.email_rounded, "Correo", "soporte@finara.app"),
              _supportTile(Icons.chat_rounded, "Chat de ayuda",
                  "Respuesta en horario laboral"),
              _supportTile(Icons.bug_report_rounded, "Reportar problema",
                  "Incluye pantalla y pasos para reproducirlo"),
            ],
          ),
        );
      },
    );
  }

  Widget _supportTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final auth = context.read<AuthProvider>(); // Obtenemos el token
    final ImagePicker picker = ImagePicker();

    // 1. Seleccionar la imagen
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Comprimimos un poco para que suba mÃ¡s rÃ¡pido
    );

    if (image == null) return;
    final imageBytes = await image.readAsBytes();
    if (!mounted) return;

    setState(() {
      _localProfileImageBytes = imageBytes;
    });

    // 2. Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    var loaderOpen = true;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/users/upload-profile-picture'),
      );

      // 3. Agregar el Token (Indispensable para tu Backend)
      request.headers['Authorization'] = 'Bearer ${auth.token}';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: image.name,
          contentType: _imageMediaType(image.name),
        ),
      );

      // 4. Enviar y procesar
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Quitar el cÃ­rculo de carga
      if (mounted && loaderOpen) {
        Navigator.pop(context);
        loaderOpen = false;
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final uploadedUrl = data['url']?.toString() ?? "";

        setState(() {
          profileImageUrl = uploadedUrl.startsWith("data:")
              ? uploadedUrl
              : "$uploadedUrl?v=${DateTime.now().millisecondsSinceEpoch}";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto de perfil actualizada ✔")),
        );
      } else {
        throw "Error del servidor: ${response.statusCode}";
      }
    } catch (e) {
      if (mounted && loaderOpen) {
        Navigator.pop(context); // Quitar carga si hay error
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al subir imagen: $e")),
      );
    }
  }

  String formatCurrency(double valor, [String? currency]) {
    final code = (currency ?? baseCurrency).toUpperCase();
    final formato = NumberFormat.currency(
      locale: 'es_CO',
      symbol: "${currencySymbols[code] ?? code} ",
      decimalDigits: code == "JPY" ? 0 : 2,
    );

    return formato.format(valor);
  }

  String formatearDinero(double valor) => formatCurrency(valor);

  void _showTopNotice(
    String message, {
    bool isError = true,
    IconData icon = Icons.info_rounded,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    final color = isError ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  String _formatInputAmount(double amount) {
    return NumberFormat.currency(
      locale: "es_CO",
      symbol: "",
      decimalDigits: 2,
    ).format(amount).trim();
  }

  double _parseMoney(String value) {
    final clean = value.trim().replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (clean.isEmpty) return 0;
    final normalized = clean.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  Future<String?> _pickGoalImageData() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 55,
      maxWidth: 900,
    );
    if (image == null) return null;
    return base64Encode(await image.readAsBytes());
  }

  void _crearMetaResponsive() => _showMetaSheet();

  void _editarMetaResponsive(int index) => _showMetaSheet(index: index);

  void _showMetaSheet({int? index}) {
    final editing = index != null;
    final meta = editing ? context.read<AuthProvider>().metas[index] : null;
    final nombre = TextEditingController(text: meta?.nombre ?? "");
    final montoMeta = TextEditingController(
        text: meta == null ? "" : _formatInputAmount(meta.montoMeta));
    final ahorroMensual = TextEditingController(
        text: meta == null ? "" : _formatInputAmount(meta.ahorroMensual));
    String? imageData = meta?.imageData;
    bool showErrors = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final nombreError = showErrors && nombre.text.trim().isEmpty;
          final montoError = showErrors && _parseMoney(montoMeta.text) <= 0;
          final ahorroError =
              showErrors && _parseMoney(ahorroMensual.text) <= 0;

          OutlineInputBorder border(bool error) => OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: error ? Colors.redAccent : const Color(0xFFE2E8F0),
                  width: error ? 1.8 : 1,
                ),
              );

          return DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.62,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Container(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 22,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF10231E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.savings_rounded,
                            color: Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          editing ? "Editar meta" : "Nueva meta",
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () async {
                      final picked = await _pickGoalImageData();
                      if (picked != null) {
                        setSheetState(() => imageData = picked);
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        height: 170,
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        child: imageData == null || imageData!.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded,
                                      color: Color(0xFF10B981), size: 42),
                                  SizedBox(height: 8),
                                  Text("Agregar foto opcional"),
                                ],
                              )
                            : Image.memory(
                                base64Decode(imageData!),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _metaField(nombre, "Nombre de la meta", Icons.flag_rounded,
                      nombreError, isDark, setSheetState),
                  if (nombreError)
                    _metaFieldError("Escribe el nombre de la meta"),
                  const SizedBox(height: 14),
                  _metaField(montoMeta, "Monto objetivo",
                      Icons.attach_money_rounded, montoError, isDark,
                      setSheetState,
                      money: true),
                  if (montoError)
                    _metaFieldError("Ingresa un monto objetivo valido"),
                  const SizedBox(height: 14),
                  _metaField(ahorroMensual, "Ahorro mensual",
                      Icons.calendar_month_rounded, ahorroError, isDark,
                      setSheetState,
                      money: true),
                  if (ahorroError)
                    _metaFieldError("Ingresa un ahorro mensual valido"),
                  if (editing) ...[
                    const SizedBox(height: 22),
                    const Text("Historial de aportes",
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 10),
                    if (meta!.aportes.isEmpty)
                      _emptyHistoryTile(isDark)
                    else
                      ...meta.aportes.take(8).map(
                            (aporte) => _aporteTile(aporte, isDark),
                          ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        setSheetState(() => showErrors = true);
                        final objetivo = _parseMoney(montoMeta.text);
                        final mensual = _parseMoney(ahorroMensual.text);
                        if (nombre.text.trim().isEmpty ||
                            objetivo <= 0 ||
                            mensual <= 0) {
                          _showTopNotice(
                            "Completa los campos obligatorios de la meta",
                            icon: Icons.error_outline_rounded,
                          );
                          return;
                        }

                        final nueva = MetaAhorro(
                          nombre: nombre.text.trim(),
                          montoMeta: objetivo,
                          ahorroMensual: mensual,
                          montoActual: meta?.montoActual ?? 0,
                          aportes: meta?.aportes,
                          imageData: imageData,
                        );

                        if (editing) {
                          context.read<AuthProvider>().editarMeta(index, nueva);
                        } else {
                          context.read<AuthProvider>().addMeta(nueva);
                        }

                        Navigator.pop(context);
                        _showTopNotice(
                          editing
                              ? "Meta actualizada correctamente"
                              : "Meta creada correctamente",
                          isError: false,
                          icon: Icons.check_circle_rounded,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        editing ? "Guardar cambios" : "Crear meta",
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _metaField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool error,
    bool isDark,
    void Function(void Function()) setSheetState, {
    bool money = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: money ? TextInputType.number : TextInputType.text,
      inputFormatters:
          money ? [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()] : null,
      onChanged: (_) => setSheetState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
        border: _metaBorder(error),
        enabledBorder: _metaBorder(error),
        focusedBorder: _metaBorder(error),
      ),
    );
  }

  OutlineInputBorder _metaBorder(bool error) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: error ? Colors.redAccent : const Color(0xFFE2E8F0),
          width: error ? 1.8 : 1,
        ),
      );

  Widget _metaFieldError(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 7, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyHistoryTile(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Text("Aun no hay aportes registrados"),
    );
  }

  Widget _aporteTile(MetaAporte aporte, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_circle_rounded, color: Color(0xFF10B981)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              DateFormat("dd/MM/yyyy").format(aporte.fecha),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            formatCurrency(aporte.monto),
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _crearMeta() {
    TextEditingController nombre = TextEditingController();
    TextEditingController montoMeta = TextEditingController();
    TextEditingController ahorroMensual = TextEditingController();
    bool showValidationErrors = false;
    XFile? pickedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final ImagePicker picker = ImagePicker();

            Future<void> pickMetaImage() async {
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                setStateDialog(() {
                  pickedImage = image;
                });
              }
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;
            OutlineInputBorder metaBorder(bool hasError) => OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: hasError ? Colors.redAccent : Colors.grey[200]!,
                    width: hasError ? 1.6 : 1,
                  ),
                );
            final nombreError =
                showValidationErrors && nombre.text.trim().isEmpty;
            final montoError =
                showValidationErrors && montoMeta.text.trim().isEmpty;
            final ahorroError =
                showValidationErrors && ahorroMensual.text.trim().isEmpty;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  //Indicador de arrastre
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 25,
                        right: 25,
                        top: 20,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //TITULO
                          const Center(
                            child: Text(
                              "Nueva meta de ahorro",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF064E3B), // verde oscuro
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          //NOMBRE
                          const Text(
                            "Nombre",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: nombre,
                            onChanged: (_) => setStateDialog(() {}),
                            decoration: InputDecoration(
                              hintText: "Ej: Viaje, Moto, Laptop...",
                              filled: true,
                              fillColor:
                                  isDark ? Colors.black12 : Colors.grey[50],
                              border: metaBorder(nombreError),
                              enabledBorder: metaBorder(nombreError),
                              focusedBorder: metaBorder(nombreError),
                            ),
                          ),
                          // Después del TextField de nombre
                          if (nombreError)
                            const Padding(
                              padding: EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                "Este campo es obligatorio",
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 12),
                              ),
                            ),

                          const SizedBox(height: 25),

                          //MONTO META
                          const Text(
                            "Monto objetivo",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: montoMeta,
                            onChanged: (_) => setStateDialog(() {}),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.attach_money,
                                  color: Color(0xFF064E3B)),
                              hintText: "0.00",
                              filled: true,
                              fillColor:
                                  isDark ? Colors.black12 : Colors.grey[50],
                              border: metaBorder(montoError),
                              enabledBorder: metaBorder(montoError),
                              focusedBorder: metaBorder(montoError),
                            ),
                          ),
                          // Después del TextField de nombre
                          if (nombreError)
                            const Padding(
                              padding: EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                "Este campo es obligatorio",
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 12),
                              ),
                            ),

                          const SizedBox(height: 25),

                          //AHORRO MENSUAL
                          const Text(
                            "Ahorro mensual",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: ahorroMensual,
                            onChanged: (_) => setStateDialog(() {}),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.savings,
                                  color: Color(0xFF064E3B)),
                              hintText: "0.00",
                              filled: true,
                              fillColor:
                                  isDark ? Colors.black12 : Colors.grey[50],
                              border: metaBorder(ahorroError),
                              enabledBorder: metaBorder(ahorroError),
                              focusedBorder: metaBorder(ahorroError),
                            ),
                          ),
                          // Después del TextField de nombre
                          if (ahorroError)
                            const Padding(
                              padding: EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                "Este campo es obligatorio",
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 12),
                              ),
                            ),

                          const SizedBox(height: 20),

                          GestureDetector(
                            onTap: pickMetaImage,
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.grey[200],
                              ),
                              child: pickedImage == null
                                  ? const Center(
                                      child: Icon(Icons.add_a_photo,
                                          size: 40, color: Colors.grey),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.file(
                                        File(pickedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 35),

                          //BTN GUARDAR
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF00C853), // verde claro
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: () async {
                                String? base64Image;

                                if (pickedImage != null) {
                                  final bytes =
                                      await pickedImage!.readAsBytes();
                                  base64Image = base64Encode(bytes);
                                }

                                setStateDialog(
                                    () => showValidationErrors = true);
                                if (nombre.text.trim().isEmpty ||
                                    montoMeta.text.trim().isEmpty ||
                                    ahorroMensual.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Completa los campos obligatorios")),
                                  );
                                  return;
                                }

                                context.read<AuthProvider>().addMeta(
                                      MetaAhorro(
                                        nombre: nombre.text,
                                        montoMeta: double.parse(montoMeta.text),
                                        ahorroMensual: double.tryParse(
                                                ahorroMensual.text) ??
                                            0,
                                        imageData: base64Image,
                                      ),
                                    );

                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Guardar meta",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editarMeta(int index) {
    final metas = context.read<AuthProvider>().metas;
    final meta = metas[index];

    TextEditingController nombre = TextEditingController(text: meta.nombre);
    TextEditingController montoMeta =
        TextEditingController(text: meta.montoMeta.toString());
    TextEditingController ahorroMensual =
        TextEditingController(text: meta.ahorroMensual.toString());
    bool showValidationErrors = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Funciones para seleccionar imagen de meta
            final ImagePicker picker = ImagePicker();
            XFile? pickedImage;

            Future<void> pickMetaImage() async {
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                pickedImage = image;
              }
            }

            // Estilos y validaciones
            final isDark = Theme.of(context).brightness == Brightness.dark;
            OutlineInputBorder metaBorder(bool hasError) => OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: hasError ? Colors.redAccent : Colors.grey[300]!,
                    width: hasError ? 1.6 : 1,
                  ),
                );
            final nombreError =
                showValidationErrors && nombre.text.trim().isEmpty;
            final montoError =
                showValidationErrors && montoMeta.text.trim().isEmpty;
            final ahorroError =
                showValidationErrors && ahorroMensual.text.trim().isEmpty;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 25,
                  right: 25,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.savings_rounded,
          size: 34,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),

      const SizedBox(height: 18),

      Text(
        "Editar Meta",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),

      const SizedBox(height: 8),

      Text(
        "Actualiza la información de tu meta",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: isDark
              ? Colors.white70
              : Colors.black54,
        ),
      ),

      const SizedBox(height: 28),

      // ================= NOMBRE =================
      TextField(
        controller: nombre,
        onChanged: (_) => setStateDialog(() {}),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: "Nombre",
          prefixIcon: Icon(
            Icons.flag_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          labelStyle: TextStyle(
            color: isDark
                ? Colors.white70
                : Colors.black54,
          ),
          hintText: "Ej: Viaje a Japón",
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white38
                : Colors.black38,
          ),
          filled: true,
          fillColor: isDark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFF5F5F5),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: nombreError
                  ? Colors.redAccent
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: nombreError
                  ? Colors.redAccent
                  : Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),

      if (nombreError)
        const Padding(
          padding: EdgeInsets.only(top: 8, left: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Este campo es obligatorio",
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ),
        ),

      const SizedBox(height: 18),

      // ================= MONTO =================
      TextField(
        controller: montoMeta,
        onChanged: (_) => setStateDialog(() {}),
        keyboardType: TextInputType.number,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: "Monto objetivo",
          prefixIcon: Icon(
            Icons.attach_money_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          labelStyle: TextStyle(
            color: isDark
                ? Colors.white70
                : Colors.black54,
          ),
          hintText: "Ej: 5000000",
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white38
                : Colors.black38,
          ),
          filled: true,
          fillColor: isDark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFF5F5F5),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: montoError
                  ? Colors.redAccent
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: montoError
                  ? Colors.redAccent
                  : Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),

      if (montoError)
        const Padding(
          padding: EdgeInsets.only(top: 8, left: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Este campo es obligatorio",
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ),
        ),

      const SizedBox(height: 18),

      // ================= AHORRO =================
      TextField(
        controller: ahorroMensual,
        onChanged: (_) => setStateDialog(() {}),
        keyboardType: TextInputType.number,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: "Ahorro mensual",
          prefixIcon: Icon(
            Icons.trending_up_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          labelStyle: TextStyle(
            color: isDark
                ? Colors.white70
                : Colors.black54,
          ),
          hintText: "Ej: 300000",
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white38
                : Colors.black38,
          ),
          filled: true,
          fillColor: isDark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFF5F5F5),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: ahorroError
                  ? Colors.redAccent
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: ahorroError
                  ? Colors.redAccent
                  : Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),

      if (ahorroError)
        const Padding(
          padding: EdgeInsets.only(top: 8, left: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Este campo es obligatorio",
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ),
        ),

      const SizedBox(height: 30),

      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: isDark
                      ? Colors.white24
                      : Colors.black12,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancelar",
                style: TextStyle(
                  color: isDark
                      ? Colors.white70
                      : Colors.black87,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
                backgroundColor:
                    Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                setStateDialog(
                    () => showValidationErrors = true);

                if (nombre.text.trim().isEmpty ||
                    montoMeta.text.trim().isEmpty ||
                    ahorroMensual.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Completa los campos obligatorios",
                      ),
                    ),
                  );
                  return;
                }

                context.read<AuthProvider>().editarMeta(
                      index,
                      MetaAhorro(
                        nombre: nombre.text,
                        montoMeta:
                            double.parse(montoMeta.text),
                        ahorroMensual:
                            double.parse(ahorroMensual.text),
                        montoActual: meta.montoActual,
                        aportes: meta.aportes,
                      ),
                    );

                Navigator.pop(context);
              },
              child: const Text(
                "Guardar",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  ),

                ),
              ),
            );
          },
        );
      },
    );
  }

  void _eliminarMeta(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar meta"),
        content: const Text("¿Seguro?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().eliminarMeta(index);
              Navigator.pop(context);
              _showTopNotice(
                "Meta eliminada correctamente",
                isError: false,
                icon: Icons.check_circle_rounded,
              );
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _agregarMontoMeta(int index) {
    final meta = context.read<AuthProvider>().metas[index];
    final controller = TextEditingController();
    bool showError = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final invalid = showError && _parseMoney(controller.text) <= 0;

          return Container(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 22,
              bottom: MediaQuery.of(context).viewInsets.bottom + 22,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF10231E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.add_card_rounded,
                          color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Agregar monto a la meta",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${formatCurrency(meta.montoActual)} de ${formatCurrency(meta.montoMeta)}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: meta.progreso.clamp(0, 1),
                          minHeight: 7,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  onChanged: (_) => setSheetState(() {}),
                  decoration: InputDecoration(
                    labelText: "Monto",
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    filled: true,
                    fillColor: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
                    border: _metaBorder(invalid),
                    enabledBorder: _metaBorder(invalid),
                    focusedBorder: _metaBorder(invalid),
                  ),
                ),
                if (invalid) _metaFieldError("Ingresa un monto valido"),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      setSheetState(() => showError = true);
                      final monto = _parseMoney(controller.text);
                      if (monto <= 0) {
                        _showTopNotice(
                          "Completa el monto para aportar",
                          icon: Icons.error_outline_rounded,
                        );
                        return;
                      }

                      context.read<AuthProvider>().agregarDineroMeta(index, monto);
                      Navigator.pop(context);
                      _showTopNotice(
                        "Monto agregado a la meta",
                        isError: false,
                        icon: Icons.check_circle_rounded,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Agregar",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _agregarAporte(int index) {
    final controller = TextEditingController();

    showDialog(
  context: context,
  builder: (_) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              "Agregar dinero",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Ingresa el monto que deseas añadir",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.attach_money_rounded,
                  color:
                      Theme.of(context).colorScheme.primary,
                ),
                hintText: "Ej: 50000",
                hintStyle: TextStyle(
                  color: isDark
                      ? Colors.white38
                      : Colors.black38,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white24
                            : Colors.black12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Cancelar",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      final monto =
                          double.tryParse(controller.text) ?? 0;

                      context
                          .read<AuthProvider>()
                          .agregarDineroMeta(index, monto);

                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Guardar",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);
  }
}
