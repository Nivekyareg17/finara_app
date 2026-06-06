import 'dart:math';
import '../../widgets/translate_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
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
      title: TranslatedText("Interes compuesto"),
      subtitle: TranslatedText("Proyecta crecimiento cuando las ganancias se reinvierten."),
      icon: Icons.show_chart_rounded,
      accentColor: const Color(0xFF2563EB),
      children: [
        CalculatorPanel(
          children: [
            TextField(
              controller: capitalController,
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
                label: TranslatedText("Capital inicial"),
                hint: ("Ej: 1.000.000"),
                icon: Icons.payments_rounded,
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
                label: TranslatedText("Tasa anual (%)"),
                hint: ("Ej: 12 o 5.5"),
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
                label: TranslatedText("Tiempo en años"),
                hint: ("Ej: 5"),
                icon: Icons.timelapse_rounded,
              ),
            ),
            const SizedBox(height: 18),
            CalculatorButton(
              label: TranslatedText("Proyectar crecimiento"), 
              onTap: calculate,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (total != null)
          ResultCard(
            title: const TranslatedText("Total acumulado"),
            value: Text("\$ ${formatter.format(total)}"), // <--- ¡AQUÍ ESTABA EL ERROR! Lo envolvemos en Text()
            caption: TranslatedText("Ganancia estimada: \$ ${formatter.format(interest)}"),
            icon: Icons.auto_graph_rounded,
            accentColor: const Color(0xFF2563EB),
          )
        else
          ResultCard(
            title: TranslatedText("Crecimiento"),
            value: TranslatedText("Intereses sobre intereses"),
            caption: TranslatedText("Ideal para inversiones de mediano y largo plazo."),
            icon: Icons.insights_rounded,
            accentColor: const Color(0xFF2563EB),
          ),
      ],
    );
  }
}