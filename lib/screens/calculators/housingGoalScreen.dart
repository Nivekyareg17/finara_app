import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../widgets/translate_widget.dart';

class HousingGoalScreen extends StatefulWidget {
  const HousingGoalScreen({super.key});

  @override
  State<HousingGoalScreen> createState() => _HousingGoalScreenState();
}

class _HousingGoalScreenState extends State<HousingGoalScreen> {
  final TextEditingController _valorViviendaController = TextEditingController();
  final TextEditingController _ahorroMensualController = TextEditingController();
  final TextEditingController _subsidiosController = TextEditingController();

  final NumberFormat _formatter = NumberFormat("#,##0", "es_CO");

  double _valorVivienda = 0;
  double _cuotaInicial = 0;
  double _montoFinanciar = 0;
  double _ahorroMensual = 0;
  double _subsidios = 0;
  double _montoFaltanteInicial = 0;
  int _mesesFaltantes = 0;
  double _cuotaMensualEstimada = 0;

  bool _isFormatting = false;

  void _formatearInput(TextEditingController controller) {
    if (_isFormatting) return;

    _isFormatting = true;

    String text = controller.text.replaceAll('.', '').replaceAll(',', '');

    if (text.isEmpty) {
      _isFormatting = false;
      return;
    }

    double value = double.tryParse(text) ?? 0;
    String formatted = _formatter.format(value);

    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    _isFormatting = false;
  }

  String _money(double value) {
    return _formatter.format(value);
  }

  void _calcularMeta() {
    setState(() {
      _valorVivienda = double.tryParse(_valorViviendaController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
      _ahorroMensual = double.tryParse(_ahorroMensualController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
      _subsidios = double.tryParse(_subsidiosController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

      _cuotaInicial = _valorVivienda * 0.30;
      _montoFaltanteInicial = _cuotaInicial - _subsidios;

      if (_montoFaltanteInicial > 0 && _ahorroMensual > 0) {
        _mesesFaltantes = (_montoFaltanteInicial / _ahorroMensual).ceil();
      } else {
        _mesesFaltantes = 0;
      }

      double excedenteAhorro = _montoFaltanteInicial < 0 ? _montoFaltanteInicial.abs() : 0;
      _montoFinanciar = (_valorVivienda * 0.70) - excedenteAhorro;

      if (_montoFinanciar < 0) _montoFinanciar = 0;

      double tasaMensual = 0.01;
      int cuotas = 240;

      if (_montoFinanciar > 0) {
        _cuotaMensualEstimada =
            (_montoFinanciar * tasaMensual) /
            (1 - pow(1 + tasaMensual, -cuotas));
      } else {
        _cuotaMensualEstimada = 0;
      }
    });
  }

  Widget _input(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      enableInteractiveSelection: false,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        label: TranslatedText(label), // Traducido
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        _formatearInput(controller);
        _calcularMeta();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const TranslatedText("Planificador de Vivienda")), // Traducido
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _input(_valorViviendaController, "Valor total del inmueble", Icons.home),
            const SizedBox(height: 15),
            _input(_subsidiosController, "Subsidios o Fondos ahorrados", Icons.account_balance),
            const SizedBox(height: 15),
            _input(_ahorroMensualController, "Tu ahorro mensual destinado", Icons.savings),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const TranslatedText(
                    "FASE 1: Ahorro Cuota Inicial (30%)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "\$${_money(_cuotaInicial)}",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 30),
                  if (_montoFaltanteInicial <= 0 && _valorVivienda > 0)
                    const Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 40),
                        SizedBox(height: 5),
                        TranslatedText(
                          "¡Meta de ahorro cumplida!",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        const TranslatedText("Tiempo estimado para lograrlo"),
                        Text(
                          "$_mesesFaltantes meses",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const TranslatedText(
                    "FASE 2: El Crédito Bancario (70%)",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  const TranslatedText("Monto a financiar con el banco:"),
                  Text(
                    "\$${_money(_montoFinanciar)}",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 30),
                  const TranslatedText("Cuota mensual estimada (A 20 años)"),
                  Text(
                    "\$${_money(_cuotaMensualEstimada)}",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}