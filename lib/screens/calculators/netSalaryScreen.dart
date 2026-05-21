import 'package:flutter/material.dart';

class NetSalaryScreen extends StatefulWidget {
  const NetSalaryScreen({super.key});

  @override
  State<NetSalaryScreen> createState() => _NetSalaryScreenState();
}

class _NetSalaryScreenState extends State<NetSalaryScreen> {
  final TextEditingController _brutoController = TextEditingController();

  // Colores profesionales
  final Color primaryGreen = const Color(0xFF10B981);
  final Color dangerColor = const Color(0xFFEF4444);
  final Color darkText = const Color(0xFF1F2937);

  // --- VARIABLES LEGALES COLOMBIA 2026 ---
  final double _smlv = 1750905; 
  final double _auxTransporteLey = 249095; 
  final double _uvt = 47065; 

  // --- ESTADO ---
  bool _esLaboral = true; 
  bool _recibeAuxilio = true; // Switch manual por si tiene ruta
  double _salarioBruto = 0;
  double _salud = 0;
  double _pension = 0;
  double _arl = 0;
  double _fsp = 0;
  double _retefuente = 0;
  double _auxCalculado = 0;
  double _salarioNeto = 0;

  void _calcularNeto() {
    setState(() {
      _salarioBruto = double.tryParse(_brutoController.text.replaceAll(',', '')) ?? 0;
      if (_salarioBruto == 0) {
        _salud = 0; _pension = 0; _arl = 0; _fsp = 0; _retefuente = 0; _auxCalculado = 0; _salarioNeto = 0;
        return;
      }

      double ibc = 0;

      if (_esLaboral) {
        // --- LABORAL ---
        ibc = _salarioBruto.clamp(0, _smlv * 25);
        _salud = ibc * 0.04;
        _pension = ibc * 0.04;
        _arl = 0;
        
        // Regla automática: > 2 SMLV pierde auxilio
        _auxCalculado = (_salarioBruto <= (_smlv * 2) && _recibeAuxilio) ? _auxTransporteLey : 0;
      } else {
        // --- OPS ---
        ibc = (_salarioBruto * 0.40).clamp(_smlv, _smlv * 25);
        _salud = ibc * 0.125;
        _pension = ibc * 0.16;
        _arl = ibc * 0.00522;
        _auxCalculado = 0;
      }

      // FSP (Solidaridad)
      _fsp = (ibc >= 4 * _smlv) ? (ibc * (ibc >= 20 * _smlv ? 0.02 : 0.01)) : 0;

      // Retención (Simplificada)
      _retefuente = _esLaboral ? (_salarioBruto > (_uvt * 95) ? (_salarioBruto * 0.05) : 0) : (_salarioBruto * 0.11);

      _salarioNeto = _salarioBruto - _salud - _pension - _arl - _fsp - _retefuente + _auxCalculado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Salario Neto 2026", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, foregroundColor: primaryGreen, elevation: 0, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Switch de contrato
            _buildContractSelector(),
            const SizedBox(height: 20),
            
            // Switch Auxilio Transporte
            if (_esLaboral)
              SwitchListTile(
                title: const Text("¿Recibe Auxilio de Transporte?", style: TextStyle(fontSize: 14)),
                value: _recibeAuxilio,
                activeColor: primaryGreen,
                onChanged: (v) { setState(() => _recibeAuxilio = v); _calcularNeto(); },
              ),

            // Input Salario
            TextField(
              controller: _brutoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: _esLaboral ? "Salario Bruto" : "Valor Contrato", prefixIcon: const Icon(Icons.attach_money), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
              onChanged: (_) => _calcularNeto(),
            ),

            const SizedBox(height: 30),
            
            // Resultados
            if (_salarioBruto > 0)
              Column(
                children: [
                  _buildDetalleRow("Salud", "- \$${_salud.toStringAsFixed(0)}", dangerColor),
                  _buildDetalleRow("Pensión", "- \$${_pension.toStringAsFixed(0)}", dangerColor),
                  if (_auxCalculado > 0) _buildDetalleRow("Auxilio Transporte", "+ \$${_auxCalculado.toStringAsFixed(0)}", primaryGreen),
                ],
              ),

            const SizedBox(height: 30),
            
            // Total
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(25)),
              child: Center(
                child: Text("NETO: \$${_salarioNeto.toStringAsFixed(0)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractSelector() {
    return Row(
      children: [
        _buildTab("Fijo", true),
        _buildTab("OPS", false),
      ],
    );
  }

  Widget _buildTab(String text, bool type) {
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() => _esLaboral = type); _calcularNeto(); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(color: _esLaboral == type ? primaryGreen : Colors.grey[200], borderRadius: BorderRadius.circular(15)),
          child: Center(child: Text(text, style: TextStyle(color: _esLaboral == type ? Colors.white : Colors.black, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value, Color color) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold))]));
  }
}