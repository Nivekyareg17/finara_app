import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({super.key});

  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _descuentoController = TextEditingController();

  final formatter = NumberFormat('#,##0.00', 'en_US');

  double _ahorro = 0;
  double _precioFinal = 0;

  void _calcularDescuento() {
    setState(() {
      double precio = double.tryParse(
            _precioController.text.replaceAll(',', ''),
          ) ??
          0;

      double descuento = double.tryParse(_descuentoController.text) ?? 0;

      if (descuento > 100) descuento = 100;

      _ahorro = precio * (descuento / 100);
      _precioFinal = precio - _ahorro;
    });
  }

  void _formatearPrecio(String value) {
    String clean = value.replaceAll(',', '');

    if (clean.isEmpty) {
      _precioController.text = '';
      return;
    }

    double number = double.tryParse(clean) ?? 0;
    String formatted = NumberFormat('#,##0', 'en_US').format(number);

    _precioController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    _calcularDescuento();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calculadora de Descuentos")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _precioController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enableInteractiveSelection: false, // <-- Bloquea el portapapeles
                inputFormatters: [
                  // Solo permite números positivos y el punto decimal
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: "Precio Original",
                  prefixIcon: Icon(Icons.sell),
                  border: OutlineInputBorder(),
                ),
                onChanged: _formatearPrecio,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _descuentoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enableInteractiveSelection: false, // <-- Bloquea el portapapeles
                inputFormatters: [
                  // Solo permite números positivos y el punto decimal
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: "Porcentaje de descuento (%)",
                  prefixIcon: Icon(Icons.percent),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _calcularDescuento(),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text("Te ahorras",
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text(
                      "\$${formatter.format(_ahorro)}",
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink),
                    ),
                    const Divider(height: 30),
                    const Text("PRECIO FINAL",
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text(
                      "\$${formatter.format(_precioFinal)}",
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}