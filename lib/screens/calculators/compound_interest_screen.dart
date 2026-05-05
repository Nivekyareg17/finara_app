import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'dart:math';

class CompoundInterestScreen extends StatefulWidget {
  const CompoundInterestScreen({super.key});

  @override
  State<CompoundInterestScreen> createState() =>
      _CompoundInterestScreenState();
}

class _CompoundInterestScreenState extends State<CompoundInterestScreen> {
  final TextEditingController capitalController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  final formatter = NumberFormat("#,##0.00", "es_CO");

  double? total;
  double? interest;

  void calculate() {
    final double P = double.tryParse(
          capitalController.text.replaceAll('.', ''),
        ) ??
        0;

    final double r = (double.tryParse(rateController.text) ?? 0) / 100;
    final double t = double.tryParse(timeController.text) ?? 0;

    setState(() {
      total = P * pow((1 + r), t);
      interest = total! - P;
    });
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Interés compuesto"),
        content: const Text(
          "Calcula cómo crece tu dinero reinvirtiendo intereses.\n\n"
          "• Capital: dinero inicial\n"
          "• Tasa: porcentaje anual (%)\n"
          "• Tiempo: años\n\n"
          "Los intereses también generan ganancias.",
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

  Widget _moneyInput(
      String label, String hint, TextEditingController controller) {
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

  Widget _input(
      String label, String hint, TextEditingController controller) {
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
      appBar: AppBar(title: const Text("Interés compuesto")),
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
                        "Capital (COP)", "Ej: 1.000.000", capitalController),
                    _input("Tasa anual (%)", "Ej: 10", rateController),
                    _input("Tiempo (años)", "Ej: 2", timeController),
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
              child: const Text("Calcular"),
            ),

            const SizedBox(height: 20),

            /// RESULTADO
            if (total != null)
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "Interés generado: \$ ${formatter.format(interest)}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Total acumulado: \$ ${formatter.format(total)}",
                        style: const TextStyle(
                          fontSize: 20,
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