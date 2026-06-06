import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';
import 'calculator_widgets.dart';
import '../../widgets/translate_widget.dart';

class SimpleInterestScreen extends StatefulWidget {
  const SimpleInterestScreen({super.key});

  @override
  State<SimpleInterestScreen> createState() => _SimpleInterestScreenState();
}

class _SimpleInterestScreenState extends State<SimpleInterestScreen> {
  final TextEditingController capitalController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final formatter = NumberFormat("#,##0.00", "es_CO");

  double? interest;
  double? total;

  void calculate() {
    final capital =
        double.tryParse(capitalController.text.replaceAll('.', '')) ?? 0;
    final rate = (double.tryParse(rateController.text) ?? 0) / 100;
    final time = double.tryParse(timeController.text) ?? 0;

    setState(() {
      interest = capital * rate * time;
      total = capital + interest!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: const TranslatedText("Interes simple"),
      subtitle: const TranslatedText("Calcula una ganancia fija sobre un capital inicial."),
      icon: Icons.trending_up_rounded,
      accentColor: const Color(0xFF10B981),
      children: [
        CalculatorPanel(
          children: [
            TextField(
              controller: capitalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              enableInteractiveSelection: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                MoneyInputFormatter(
                  thousandSeparator: ThousandSeparator.Period,
                  mantissaLength: 0,
                ),
              ],
              decoration: calculatorInputDecoration(
                label: const TranslatedText("Capital"),
                hint: "Ej: 1.000.000",
                icon: Icons.account_balance_wallet_rounded,
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
                label: const TranslatedText("Tasa anual (%)"),
                hint: "Ej: 10 o 2.4",
                icon: Icons.percent_rounded,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: timeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enableInteractiveSelection: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: calculatorInputDecoration(
                label: const TranslatedText("Tiempo en años"),
                hint: "Ej: 2 o 1.5",
                icon: Icons.calendar_month_rounded,
              ),
            ),
            const SizedBox(height: 18),
            CalculatorButton(
                label: const TranslatedText("Calcular interes"), 
                onTap: calculate
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (interest != null)
          ResultCard(
            title: const TranslatedText("Interes generado"),
            value: Text("\$ ${formatter.format(interest)}"),
            caption: TranslatedText("Total estimado: \$ ${formatter.format(total)}"),
            icon: Icons.savings_rounded,
          )
        else
          const ResultCard(
            title: TranslatedText("Formula"),
            value: TranslatedText("Capital x tasa x tiempo"),
            caption: TranslatedText("Completa los datos para ver el resultado."),
            icon: Icons.functions_rounded,
          ),
      ],
    );
  }
}