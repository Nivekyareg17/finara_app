import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';
import 'calculator_widgets.dart';

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
    final amount =
        double.tryParse(amountController.text.replaceAll('.', '')) ?? 0;
    final rate = (double.tryParse(rateController.text) ?? 0) / 100;
    final months = int.tryParse(monthsController.text) ?? 0;

    if (months == 0) return;

    setState(() {
      cuota = rate == 0
          ? amount / months
          : amount * (rate * pow(1 + rate, months)) /
              (pow(1 + rate, months) - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: "Prestamos",
      subtitle: "Estima la cuota mensual antes de tomar un credito.",
      icon: Icons.account_balance_rounded,
      accentColor: const Color(0xFF7C3AED),
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
                label: "Monto del prestamo",
                hint: "Ej: 5.000.000",
                icon: Icons.credit_card_rounded,
                prefixText: "\$ ",
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: calculatorInputDecoration(
                label: "Tasa mensual (%)",
                hint: "Ej: 2",
                icon: Icons.percent_rounded,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: monthsController,
              keyboardType: TextInputType.number,
              decoration: calculatorInputDecoration(
                label: "Numero de cuotas",
                hint: "Ej: 24",
                icon: Icons.event_repeat_rounded,
              ),
            ),
            const SizedBox(height: 18),
            CalculatorButton(label: "Calcular cuota", onTap: calculate),
          ],
        ),
        const SizedBox(height: 16),
        if (cuota != null)
          ResultCard(
            title: "Pago mensual",
            value: "\$ ${formatter.format(cuota)}",
            caption: "Usa este valor para comparar opciones.",
            icon: Icons.receipt_long_rounded,
            accentColor: const Color(0xFF7C3AED),
          )
        else
          const ResultCard(
            title: "Consejo",
            value: "Evalua la cuota",
            caption: "Una buena cuota cabe en tu presupuesto mensual.",
            icon: Icons.tips_and_updates_rounded,
            accentColor: Color(0xFF7C3AED),
          ),
      ],
    );
  }
}
