import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';
import 'calculator_widgets.dart';

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
    final amount =
        double.tryParse(amountController.text.replaceAll('.', '')) ?? 0;
    final rate = (double.tryParse(rateController.text) ?? 0) / 100;
    final years = double.tryParse(yearsController.text) ?? 0;

    setState(() {
      futureValue = amount * (1 + rate * years);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: "Inflacion",
      subtitle: "Mide como cambia el precio de tus compras con el tiempo.",
      icon: Icons.price_change_rounded,
      accentColor: const Color(0xFFEF4444),
      children: [
        CalculatorPanel(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                MoneyInputFormatter(
                  thousandSeparator: ThousandSeparator.Period,
                  mantissaLength: 0,
                ),
              ],
              decoration: calculatorInputDecoration(
                label: "Valor actual",
                hint: "Ej: 1.000.000",
                icon: Icons.shopping_bag_rounded,
                prefixText: "\$ ",
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: calculatorInputDecoration(
                label: "Inflacion anual (%)",
                hint: "Ej: 8",
                icon: Icons.percent_rounded,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: yearsController,
              keyboardType: TextInputType.number,
              decoration: calculatorInputDecoration(
                label: "Tiempo en anos",
                hint: "Ej: 5",
                icon: Icons.hourglass_bottom_rounded,
              ),
            ),
            const SizedBox(height: 18),
            CalculatorButton(label: "Calcular valor futuro", onTap: calculate),
          ],
        ),
        const SizedBox(height: 16),
        if (futureValue != null)
          ResultCard(
            title: "Valor futuro estimado",
            value: "\$ ${formatter.format(futureValue)}",
            caption: "Referencia para planear compras futuras.",
            icon: Icons.trending_up_rounded,
            accentColor: const Color(0xFFEF4444),
          )
        else
          const ResultCard(
            title: "Poder adquisitivo",
            value: "Precio hoy vs futuro",
            caption: "Te ayuda a anticipar aumentos de precio.",
            icon: Icons.query_stats_rounded,
            accentColor: Color(0xFFEF4444),
          ),
      ],
    );
  }
}
