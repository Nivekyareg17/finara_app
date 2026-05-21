import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final TextEditingController _montoController = TextEditingController();
  
  // Colores profesionales
  final Color primaryGreen = const Color(0xFF10B981);
  final Color surfaceGreen = const Color(0xFFECFDF5);
  final Color darkText = const Color(0xFF1F2937);

  // Variables de estado
  double _resultado = 0;
  double _tasaActual = 0;
  bool _isLoading = false;
  
  String _fromCurrency = 'USD';
  String _toCurrency = 'COP';

  // Lista de monedas más comunes
  final List<String> _monedas = ['USD', 'COP', 'EUR', 'MXN', 'BRL', 'ARS', 'GBP', 'CAD', 'JPY'];

  @override
  void initState() {
    super.initState();
    // Traemos la tasa de cambio apenas se abre la pantalla
    _fetchTasaCambio();
  }

  // --- CONEXIÓN A LA API ---
  Future<void> _fetchTasaCambio() async {
    setState(() => _isLoading = true);
    
    try {
      // API Gratuita y sin llave que soporta COP
      final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/$_fromCurrency');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tasaActual = data['rates'][_toCurrency].toDouble();
          _convertir(); // Recalcula si ya había un número escrito
        });
      }
    } catch (e) {
      debugPrint("Error fetching currency: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al conectar. Verifica tu internet."), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA DE CONVERSIÓN ---
  void _convertir() {
    setState(() {
      double monto = double.tryParse(_montoController.text.replaceAll(',', '')) ?? 0;
      _resultado = monto * _tasaActual;
    });
  }

  void _intercambiarMonedas() {
    setState(() {
      String temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    // Al voltearlas, necesitamos pedir la tasa de nuevo
    _fetchTasaCambio(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Divisas en Tiempo Real", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- CAMPO DE INGRESO ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _montoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkText),
                decoration: InputDecoration(
                  labelText: "Monto a convertir",
                  labelStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                  prefixIcon: Icon(Icons.attach_money, color: primaryGreen, size: 30),
                  border: InputBorder.none,
                ),
                onChanged: (v) => _convertir(),
              ),
            ),
            
            const SizedBox(height: 30),

            // --- SELECTORES DE MONEDA (CON ANIMACIÓN DE INTERCAMBIO) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDropdown(_fromCurrency, (val) {
                  setState(() => _fromCurrency = val!);
                  _fetchTasaCambio();
                }),
                
                // Botón de Intercambio Animado
                Material(
                  color: surfaceGreen,
                  shape: const CircleBorder(),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: _intercambiarMonedas,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(Icons.swap_horiz_rounded, color: primaryGreen, size: 28),
                    ),
                  ),
                ),

                _buildDropdown(_toCurrency, (val) {
                  setState(() => _toCurrency = val!);
                  _fetchTasaCambio();
                }),
              ],
            ),

            const SizedBox(height: 40),

            // --- TARJETA DE RESULTADO (ANIMADA) ---
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen, primaryGreen.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Text("Monto Convertido", style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  
                  // Efecto de desvanecimiento al cambiar el número
                  _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: Text(
                          "\$${_resultado.toStringAsFixed(2)} $_toCurrency",
                          key: ValueKey<double>(_resultado), // El key fuerza la animación cuando el valor cambia
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      "Tasa de mercado: 1 $_fromCurrency = ${_tasaActual.toStringAsFixed(2)} $_toCurrency",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget reutilizable para los selectores (Dropdowns)
  Widget _buildDropdown(String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceGreen,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryGreen.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryGreen),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
          items: _monedas.map((String coin) {
            return DropdownMenuItem<String>(
              value: coin,
              child: Text(coin),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}