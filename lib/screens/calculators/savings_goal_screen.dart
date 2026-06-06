import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';
import 'calculator_widgets.dart';
import '../../widgets/translate_widget.dart';

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
    final goal = double.tryParse(goalController.text.replaceAll('.', '')) ?? 0;
    final rate = (double.tryParse(rateController.text) ?? 0) / 100;
    final months = int.tryParse(monthsController.text) ?? 0;

    if (months == 0) return;

    setState(() {
      monthlySaving =
          rate == 0 ? goal / months : (goal * rate) / (pow(1 + rate, months) - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: const TranslatedText("Ahorro"),
      subtitle: const TranslatedText("Define cuanto necesitas guardar cada mes para llegar a tu meta."),
      icon: Icons.savings_rounded,
      accentColor: const Color(0xFFF59E0B),
      children: [
        CalculatorPanel(
          children: [
            TextField(
              controller: goalController,
              keyboardType: TextInputType.number,
              enableInteractiveSelection: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                MoneyInputFormatter(
                  thousandSeparator: ThousandSeparator.Period,
                  mantissaLength: 0,
                ),
              ],
              decoration: calculatorInputDecoration(
                label: const TranslatedText("Meta de ahorro"),
                hint: "Ej: 3.000.000",
                icon: Icons.flag_rounded,
                prefixText: "\$ ",
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enableInteractiveSelection: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: calculatorInputDecoration(
                label: const TranslatedText("Rendimiento mensual (%)"),
                hint: "Ej: 1 o 0.5%",
                icon: Icons.percent_rounded,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: monthsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              enableInteractiveSelection: false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: calculatorInputDecoration(
                label: const TranslatedText("Tiempo en meses"),
                hint: "Ej: 12",
                icon: Icons.calendar_view_month_rounded,
              ),
            ),
            const SizedBox(height: 18),
            CalculatorButton(
                label: const TranslatedText("Calcular ahorro"), 
                onTap: calculate
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (monthlySaving != null)
          ResultCard(
            title: const TranslatedText("Ahorro mensual"),
            value: Text("\$ ${formatter.format(monthlySaving)}"),
            caption: TranslatedText("Guarda este monto para llegar a tiempo."),
            icon: Icons.check_circle_rounded,
            accentColor: const Color(0xFFF59E0B),
          )
        else
          const ResultCard(
            title: TranslatedText("Plan"),
            value: TranslatedText("Meta + tiempo"),
            caption: TranslatedText("Convierte una meta grande en cuotas mensuales."),
            icon: Icons.route_rounded,
            accentColor: Color(0xFFF59E0B),
          ),
      ],
    );
  }
}