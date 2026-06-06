import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../widgets/translate_widget.dart';

class NetSalaryScreen extends StatefulWidget {
  const NetSalaryScreen({super.key});

  @override
  State<NetSalaryScreen> createState() => _NetSalaryScreenState();
}

class _NetSalaryScreenState extends State<NetSalaryScreen> {
  final TextEditingController _brutoController = TextEditingController();

  final NumberFormat _formatter = NumberFormat("#,##0", "es_CO");

  final Color primaryGreen = const Color(0xFF10B981);
  final Color dangerColor = const Color(0xFFEF4444);

  final double _smlv = 1750905;
  final double _auxTransporteLey = 249095;
  final double _uvt = 47065;

  bool _esLaboral = true;
  bool _recibeAuxilio = true;

  double _salarioBruto = 0;
  double _salud = 0;
  double _pension = 0;
  double _arl = 0;
  double _fsp = 0;
  double _retefuente = 0;
  double _auxCalculado = 0;
  double _salarioNeto = 0;

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

  double _parse(String text) {
    return double.tryParse(text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  }

  String _money(double value) {
    return _formatter.format(value);
  }

  void _calcularNeto() {
    setState(() {
      _salarioBruto = _parse(_brutoController.text);
      if (_salarioBruto == 0) {
        _salud = 0; _pension = 0; _arl = 0; _fsp = 0; _retefuente = 0;
        _auxCalculado = 0; _salarioNeto = 0;
        return;
      }
      double ibc = 0;
      if (_esLaboral) {
        ibc = _salarioBruto.clamp(0, _smlv * 25);
        _salud = ibc * 0.04;
        _pension = ibc * 0.04;
        _arl = 0;
        _auxCalculado = (_salarioBruto <= (_smlv * 2) && _recibeAuxilio) ? _auxTransporteLey : 0;
      } else {
        ibc = (_salarioBruto * 0.40).clamp(_smlv, _smlv * 25);
        _salud = ibc * 0.125;
        _pension = ibc * 0.16;
        _arl = ibc * 0.00522;
        _auxCalculado = 0;
      }
      _fsp = (ibc >= 4 * _smlv) ? (ibc * (ibc >= 20 * _smlv ? 0.02 : 0.01)) : 0;
      _retefuente = _esLaboral ? (_salarioBruto > (_uvt * 95) ? (_salarioBruto * 0.05) : 0) : (_salarioBruto * 0.11);
      _salarioNeto = _salarioBruto - _salud - _pension - _arl - _fsp - _retefuente + _auxCalculado;
    });
  }

  Widget _input() {
    return TextField(
      controller: _brutoController,
      keyboardType: TextInputType.number,
      enableInteractiveSelection: false,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        label: TranslatedText(_esLaboral ? "Salario Bruto" : "Valor Contrato"),
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onChanged: (_) {
        _formatearInput(_brutoController);
        _calcularNeto();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const TranslatedText("Salario Neto 2026", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildContractSelector(),
            const SizedBox(height: 20),
            if (_esLaboral)
              SwitchListTile(
                title: const TranslatedText("¿Recibe Auxilio de Transporte?\n(Solo para <= 2 SMLV)", style: TextStyle(fontSize: 14)),
                value: (_salarioBruto <= (_smlv * 2)) ? _recibeAuxilio : false,
                activeColor: primaryGreen,
                onChanged: (_salarioBruto <= (_smlv * 2)) ? (v) {
                  setState(() => _recibeAuxilio = v);
                  _calcularNeto();
                } : null,
              ),
            _input(),
            const SizedBox(height: 30),
            if (_salarioBruto > 0)
              Column(
                children: [
                  _buildDetalleRow("Salud", "- \$${_money(_salud)}", dangerColor),
                  _buildDetalleRow("Pensión", "- \$${_money(_pension)}", dangerColor),
                  if (_auxCalculado > 0)
                    _buildDetalleRow("Auxilio Transporte", "+ \$${_money(_auxCalculado)}", primaryGreen),
                ],
              ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(25)),
              child: Center(
                child: Text(
                  "NETO: \$${_money(_salarioNeto)}",
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                ),
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
        onTap: () {
          setState(() => _esLaboral = type);
          _calcularNeto();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: _esLaboral == type ? primaryGreen : Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(child: TranslatedText(text, style: TextStyle(color: _esLaboral == type ? Colors.white : Colors.black, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TranslatedText(label),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}