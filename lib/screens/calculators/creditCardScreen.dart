import 'package:flutter/material.dart';
import 'dart:math';

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

  double _totalConInteres = 0;
  double _cashbackGanado = 0;
  double _diferencia = 0;

  void _calcularDiferencia() {
    setState(() {
      double compra = double.tryParse(_compraController.text) ?? 0;
      int cuotas = int.tryParse(_cuotasController.text) ?? 1;
      double tasaMensual = (double.tryParse(_tasaController.text) ?? 0) / 100;
      double cashbackPorcentaje = (double.tryParse(_cashbackController.text) ?? 0) / 100;

      _cashbackGanado = compra * cashbackPorcentaje;

      if (cuotas <= 1 || tasaMensual == 0) {
        _totalConInteres = compra;
      } else {
        // Fórmula de amortización estándar para cuota fija
        double cuotaFija = (compra * tasaMensual) / (1 - pow(1 + tasaMensual, -cuotas));
        _totalConInteres = cuotaFija * cuotas;
      }

      // Lo que realmente pierdes (Intereses pagados - Cashback ganado)
      _diferencia = (_totalConInteres - compra) - _cashbackGanado;
    });
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
            TextField(controller: _compraController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Valor de la compra", border: OutlineInputBorder()), onChanged: (v) => _calcularDiferencia()),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: TextField(controller: _cuotasController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Meses / Cuotas", border: OutlineInputBorder()), onChanged: (v) => _calcularDiferencia())),
                const SizedBox(width: 15),
                Expanded(child: TextField(controller: _tasaController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Tasa Interés M.V (%)", border: OutlineInputBorder()), onChanged: (v) => _calcularDiferencia())),
              ],
            ),
            const SizedBox(height: 15),
            TextField(controller: _cashbackController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "% de Cashback de tu tarjeta", border: OutlineInputBorder()), onChanged: (v) => _calcularDiferencia()),
            const SizedBox(height: 30),
            
            _buildResultRow("Pagas a 1 cuota:", "\$${(_compraController.text.isNotEmpty ? double.parse(_compraController.text) - _cashbackGanado : 0).toStringAsFixed(2)}", Colors.green),
            _buildResultRow("Pagas a varias cuotas:", "\$${_totalConInteres.toStringAsFixed(2)}", Colors.redAccent),
            const Divider(height: 30),
            Text(_diferencia > 0 ? "El banco gana:" : "Tú ganas:", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            Text("\$${_diferencia.abs().toStringAsFixed(2)}", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _diferencia > 0 ? Colors.red : Colors.green)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 16)), Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))]),
    );
  }
}