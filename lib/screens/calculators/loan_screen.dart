import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'dart:math';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController monthsController = TextEditingController();

  final formatter = NumberFormat("#,##0.00", "es_CO");

  double? cuota;

  void calculate() {
    final double P = double.tryParse(
          amountController.text.replaceAll('.', ''),
        ) ??
        0;

    final double r = (double.tryParse(rateController.text) ?? 0) / 100;
    final int n = int.tryParse(monthsController.text) ?? 0;

    if (r == 0 || n == 0) return;

    setState(() {
      cuota = P * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
    });
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cuota de préstamo"),
        content: const Text(
          "Calcula cuánto debes pagar cada mes.\n\n"
          "• Monto: dinero prestado\n"
          "• Tasa mensual (%)\n"
          "• Número de cuotas (meses)\n\n"
          "Usado en créditos y préstamos.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Entendido"),
          )
        ],
      ),
    );
  }

  Widget _moneyInput(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          MoneyInputFormatter(
            thousandSeparator: ThousandSeparator.Period,
            mantissaLength: 0,
          ),
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: "\$ ",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _input(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Préstamos")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// INPUTS
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _moneyInput(
                        "Monto del préstamo (COP)", "Ej: 1.000.000", amountController),
                    _input("Tasa mensual (%)", "Ej: 2", rateController),
                    _input("Número de cuotas (meses)", "Ej: 12", monthsController),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// AYUDA
            TextButton.icon(
              onPressed: _showHelp,
              icon: const Icon(Icons.info_outline),
              label: const Text("¿Qué es esto?"),
            ),

            const SizedBox(height: 10),

            /// BOTÓN
            ElevatedButton(
              onPressed: calculate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
              ),
              child: const Text("Calcular cuota"),
            ),

            const SizedBox(height: 20),

            /// RESULTADO
            if (cuota != null)
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "Pago mensual",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "\$ ${formatter.format(cuota)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}