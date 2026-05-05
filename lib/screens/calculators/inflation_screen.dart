import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class InflationScreen extends StatefulWidget {
  const InflationScreen({super.key});

  @override
  State<InflationScreen> createState() => _InflationScreenState();
}

class _InflationScreenState extends State<InflationScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController yearsController = TextEditingController();

  final formatter = NumberFormat("#,##0.00", "es_CO");

  double? futureValue;

  void calculate() {
    final double P = double.tryParse(
          amountController.text.replaceAll('.', ''),
        ) ??
        0;

    final double r = (double.tryParse(rateController.text) ?? 0) / 100;
    final double t = double.tryParse(yearsController.text) ?? 0;

    setState(() {
      futureValue = P * (1 + r * t);
    });
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Inflación"),
        content: const Text(
          "Calcula cuánto aumentará el precio de algo con el tiempo.\n\n"
          "• Valor actual: precio hoy\n"
          "• Inflación anual (%)\n"
          "• Tiempo en años\n\n"
          "Sirve para entender cómo el dinero pierde valor.",
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
      appBar: AppBar(title: const Text("Inflación")),
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
                        "Valor actual (COP)", "Ej: 1.000.000", amountController),
                    _input("Inflación anual (%)", "Ej: 8", rateController),
                    _input("Tiempo (años)", "Ej: 5", yearsController),
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
              child: const Text("Calcular inflación"),
            ),

            const SizedBox(height: 20),

            /// RESULTADO
            if (futureValue != null)
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "Valor futuro estimado",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "\$ ${formatter.format(futureValue)}",
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