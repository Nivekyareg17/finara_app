import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class SavingsGoalScreen extends StatefulWidget {
  const SavingsGoalScreen({super.key});

  @override
  State<SavingsGoalScreen> createState() => _SavingsGoalScreenState();
}

class _SavingsGoalScreenState extends State<SavingsGoalScreen> {
  final TextEditingController goalController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController monthsController = TextEditingController();

  final formatter = NumberFormat("#,##0.00", "es_CO");

  double? monthlySaving;

  void calculate() {
    final double FV = double.tryParse(goalController.text) ?? 0;
    final double r = (double.tryParse(rateController.text) ?? 0) / 100;
    final int n = int.tryParse(monthsController.text) ?? 0;

    if (r == 0 || n == 0) return;

    setState(() {
      monthlySaving = (FV * r) / (pow(1 + r, n) - 1);
    });
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ahorro con meta"),
        content: const Text(
          "Calcula cuánto debes ahorrar cada mes para alcanzar una meta.\n\n"
          "• Meta: dinero que quieres lograr\n"
          "• Tasa: rendimiento mensual (%)\n"
          "• Meses: tiempo para lograrlo\n\n"
          "Ideal para ahorrar para viajes, compras o inversión.",
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
      appBar: AppBar(title: const Text("Ahorro con meta")),
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
                    _input("Meta de ahorro (COP)", "Ej: 1,000,000", goalController),
                    _input("Tasa mensual (%)", "Ej: 2", rateController),
                    _input("Tiempo (meses)", "Ej: 12", monthsController),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
              ),
              child: const Text("Calcular ahorro"),
            ),

            const SizedBox(height: 20),

            /// RESULTADO
            if (monthlySaving != null)
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "Ahorro mensual necesario",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatter.format(monthlySaving),
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