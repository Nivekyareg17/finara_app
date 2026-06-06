import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; 
import 'dart:math'; 
import 'calculator_widgets.dart';
import '../../widgets/translate_widget.dart';

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
      futureValue = amount * pow(1 + rate, years);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: const TranslatedText("Inflacion"),
      subtitle: const TranslatedText("Mide como cambia el precio de tus compras con el tiempo."),
      icon: Icons.price_change_rounded,
      accentColor: const Color(0xFFEF4444),
      children: [
        CalculatorPanel(
          children: [
            TextField(
              controller: amountController,
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
                label: const TranslatedText("Valor actual"),
                hint: "Ej: 1.000.000",
                icon: Icons.shopping_bag_rounded,
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
                label: const TranslatedText("Inflacion anual (%)"),
                hint: "Ej: 8 o 3.5",
                icon: Icons.percent_rounded,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: yearsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enableInteractiveSelection: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: calculatorInputDecoration(
                label: const TranslatedText("Tiempo en años"),
                hint: "Ej: 5",
                icon: Icons.hourglass_bottom_rounded,
              ),
            ),
            const SizedBox(height: 18),
            CalculatorButton(
                label: const TranslatedText("Calcular valor futuro"), 
                onTap: calculate
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (futureValue != null)
          ResultCard(
            title: const TranslatedText("Valor futuro estimado"),
            value: Text("\$ ${formatter.format(futureValue)}"),
            caption: TranslatedText("Ganancia estimada: \$ ${formatter.format(futureValue)}"),
            icon: Icons.trending_up_rounded,
            accentColor: const Color(0xFFEF4444),
          )
        else
          const ResultCard(
            title: TranslatedText("Poder adquisitivo"),
            value: TranslatedText("Precio hoy vs futuro"),
            caption: TranslatedText("Te ayuda a anticipar aumentos de precio."),
            icon: Icons.query_stats_rounded,
            accentColor: Color(0xFFEF4444),
          ),
      ],
    );
  }
}