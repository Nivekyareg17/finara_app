import 'package:flutter/material.dart';
import 'dart:math'; // 👈 Necesario para la fórmula del crédito

class HousingGoalScreen extends StatefulWidget {
  const HousingGoalScreen({super.key});

  @override
  State<HousingGoalScreen> createState() => _HousingGoalScreenState();
}

class _HousingGoalScreenState extends State<HousingGoalScreen> {
  final TextEditingController _valorViviendaController = TextEditingController();
  final TextEditingController _ahorroMensualController = TextEditingController();
  final TextEditingController _subsidiosController = TextEditingController();

  double _valorVivienda = 0;
  double _cuotaInicial = 0; // 30% del valor total
  double _montoFinanciar = 0; // 70% del valor total (El Crédito)
  double _ahorroMensual = 0;
  double _subsidios = 0;
  double _montoFaltanteInicial = 0;
  int _mesesFaltantes = 0;
  
  double _cuotaMensualEstimada = 0; // Cuota del banco

  void _calcularMeta() {
    setState(() {
      _valorVivienda = double.tryParse(_valorViviendaController.text.replaceAll(',', '')) ?? 0;
      _ahorroMensual = double.tryParse(_ahorroMensualController.text.replaceAll(',', '')) ?? 0;
      _subsidios = double.tryParse(_subsidiosController.text.replaceAll(',', '')) ?? 0;

      // 1. FASE DE AHORRO (30%)
      _cuotaInicial = _valorVivienda * 0.30;
      _montoFaltanteInicial = _cuotaInicial - _subsidios;

      if (_montoFaltanteInicial > 0 && _ahorroMensual > 0) {
        _mesesFaltantes = (_montoFaltanteInicial / _ahorroMensual).ceil();
      } else {
        _mesesFaltantes = 0;
      }

      // 2. FASE DE CRÉDITO (70%)
      // Si los subsidios/ahorros superan el 30%, ese excedente reduce el crédito
      double excedenteAhorro = _montoFaltanteInicial < 0 ? _montoFaltanteInicial.abs() : 0;
      _montoFinanciar = (_valorVivienda * 0.70) - excedenteAhorro;
      
      if (_montoFinanciar < 0) _montoFinanciar = 0;

      // Simulación de cuota: Tasa estimada 1% M.V. a 20 años (240 meses)
      double tasaMensual = 0.01;
      int cuotas = 240;
      
      if (_montoFinanciar > 0) {
        _cuotaMensualEstimada = (_montoFinanciar * tasaMensual) / (1 - pow(1 + tasaMensual, -cuotas));
      } else {
        _cuotaMensualEstimada = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Planificador de Vivienda")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _valorViviendaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Valor total del inmueble", prefixIcon: Icon(Icons.home), border: OutlineInputBorder()),
              onChanged: (val) => _calcularMeta(),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _subsidiosController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Subsidios o Fondos ahorrados", prefixIcon: Icon(Icons.account_balance), border: OutlineInputBorder()),
              onChanged: (val) => _calcularMeta(),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _ahorroMensualController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Tu ahorro mensual destinado", prefixIcon: Icon(Icons.savings), border: OutlineInputBorder()),
              onChanged: (val) => _calcularMeta(),
            ),
            const SizedBox(height: 30),
            
            // --- RESULTADOS: FASE DE AHORRO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  const Text("FASE 1: Ahorro Cuota Inicial (30%)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  const SizedBox(height: 10),
                  Text("\$${_cuotaInicial.toStringAsFixed(2)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const Divider(height: 30),
                  
                  if (_montoFaltanteInicial <= 0 && _valorVivienda > 0)
                    const Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 40),
                        SizedBox(height: 5),
                        Text("¡Meta de ahorro cumplida!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        const Text("Tiempo estimado para lograrlo", style: TextStyle(fontSize: 14, color: Colors.grey)),
                        Text("$_mesesFaltantes meses", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.deepPurple)),
                      ],
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // --- RESULTADOS: FASE DE CRÉDITO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  const Text("FASE 2: El Crédito Bancario (70%)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 10),
                  const Text("Monto a financiar con el banco:", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  Text("\$${_montoFinanciar.toStringAsFixed(2)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const Divider(height: 30),
                  const Text("Cuota mensual estimada (A 20 años)", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  Text("\$${_cuotaMensualEstimada.toStringAsFixed(2)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.blue)),
                  const SizedBox(height: 10),
                  const Text("*Simulación con tasa referencial del 1% M.V.", style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}