import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class CreditCardScreen extends StatefulWidget {
  const CreditCardScreen({super.key});

  @override
  State<CreditCardScreen> createState() => _CreditCardScreenState();
}

class _CreditCardScreenState extends State<CreditCardScreen> {
  final TextEditingController _compraController = TextEditingController();
  final TextEditingController _cuotasController = TextEditingController();
  final TextEditingController _tasaController = TextEditingController(text: "2.5");
  final TextEditingController _cashbackController = TextEditingController(text: "1.0");

  final NumberFormat _formatter = NumberFormat("#,##0", "es_CO");

  double _totalConInteres = 0;
  double _cashbackGanado = 0;
  double _diferencia = 0;

  bool _isFormatting = false;

  void _formatearInput(TextEditingController controller) {
    if (_isFormatting) return;

    _isFormatting = true;

    String text = controller.text.replaceAll('.', '').replaceAll(',', '');

    if (text.isEmpty) {
      _isFormatting = false;
      return;
    }

    double value = double.tryParse(text) ?? 0;
    String formatted = _formatter.format(value);

    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    _isFormatting = false;
  }

  String _money(double value) {
    return _formatter.format(value);
  }

  double _parse(String text) {
    return double.tryParse(text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  }

  void _calcularDiferencia() {
    setState(() {
      double compra = _parse(_compraController.text);
      int cuotas = int.tryParse(_cuotasController.text) ?? 1;
      double tasaMensual = (double.tryParse(_tasaController.text) ?? 0) / 100;
      double cashbackPorcentaje = (double.tryParse(_cashbackController.text) ?? 0) / 100;

      _cashbackGanado = compra * cashbackPorcentaje;

      if (cuotas <= 1 || tasaMensual == 0) {
        _totalConInteres = compra;
      } else {
        double cuotaFija = (compra * tasaMensual) / (1 - pow(1 + tasaMensual, -cuotas));
        _totalConInteres = cuotaFija * cuotas;
      }

      _diferencia = (_totalConInteres - compra) - _cashbackGanado;
    });
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    bool format = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      enableInteractiveSelection: false, 
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, 
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) {
        if (format) _formatearInput(controller);
        _calcularDiferencia();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tarjeta vs Cashback")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _input(_compraController, "Valor de la compra", format: true),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _input(_cuotasController, "Meses / Cuotas"),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _tasaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enableInteractiveSelection: false, 
                    inputFormatters: [
                      
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Tasa Interés M.V (%)",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _calcularDiferencia(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _cashbackController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enableInteractiveSelection: false, 
              inputFormatters: [
                
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: "% de Cashback de tu tarjeta",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _calcularDiferencia(),
            ),

            const SizedBox(height: 30),

            _buildResultRow(
              "Pagas a 1 cuota:",
              "\$${_money(_parse(_compraController.text) - _cashbackGanado)}",
              Colors.green,
            ),

            _buildResultRow(
              "Pagas a varias cuotas:",
              "\$${_money(_totalConInteres)}",
              Colors.redAccent,
            ),

            const Divider(height: 30),

            Text(
              _diferencia > 0 ? "El banco gana:" : "Tú ganas:",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            Text(
              "\$${_money(_diferencia.abs())}",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: _diferencia > 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}