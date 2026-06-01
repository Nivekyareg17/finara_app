import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';
import 'calculator_widgets.dart';

class CompoundInterestScreen extends StatefulWidget {
  const CompoundInterestScreen({super.key});

  @override
  State<CompoundInterestScreen> createState() => _CompoundInterestScreenState();
}

class _CompoundInterestScreenState extends State<CompoundInterestScreen> {
  final TextEditingController capitalController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final formatter = NumberFormat("#,##0.00", "es_CO");

  double? total;
  double? interest;

  void calculate() {
    final capital =
        double.tryParse(capitalController.text.replaceAll('.', '')) ?? 0;
    final rate = (double.tryParse(rateController.text) ?? 0) / 100;
    final time = double.tryParse(timeController.text) ?? 0;

    setState(() {
      total = capital * pow(1 + rate, time);
      interest = total! - capital;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: "Interes compuesto",
      subtitle: "Proyecta crecimiento cuando las ganancias se reinvierten.",
      icon: Icons.show_chart_rounded,
      accentColor: const Color(0xFF2563EB),
      children: [
        CalculatorPanel(
          children: [
            TextField(
              controller: capitalController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                MoneyInputFormatter(
                  thousandSeparator: ThousandSeparator.Period,
                  mantissaLength: 0,
                ),
              ],
              decoration: calculatorInputDecoration(
                label: "Capital inicial",
                hint: "Ej: 1.000.000",
                icon: Icons.payments_rounded,
                prefixText: "\$ ",
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: calculatorInputDecoration(
                label: "Tasa anual (%)",
                hint: "Ej: 12 o 5.5%",
                icon: Icons.percent_rounded,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: timeController,
              keyboardType: TextInputType.number,
              decoration: calculatorInputDecoration(
                label: "Tiempo en años",
                hint: "Ej: 5",
                icon: Icons.timelapse_rounded,
              ),
            ),
            const SizedBox(height: 18),
            CalculatorButton(label: "Proyectar crecimiento", onTap: calculate),
          ],
        ),
        const SizedBox(height: 16),
        if (total != null)
          ResultCard(
            title: "Total acumulado",
            value: "\$ ${formatter.format(total)}",
            caption: "Ganancia estimada: \$ ${formatter.format(interest)}",
            icon: Icons.auto_graph_rounded,
            accentColor: const Color(0xFF2563EB),
          )
        else
          const ResultCard(
            title: "Crecimiento",
            value: "Intereses sobre intereses",
            caption: "Ideal para inversiones de mediano y largo plazo.",
            icon: Icons.insights_rounded,
            accentColor: Color(0xFF2563EB),
          ),
      ],
    );
  }
}
