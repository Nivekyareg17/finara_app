import 'package:flutter/material.dart';
import 'compound_interest_screen.dart';
import 'inflation_screen.dart';
import 'loan_screen.dart';
import 'savings_goal_screen.dart';
import 'simple_interest_screen.dart';
import 'currencyScreen.dart';
import 'creditCardScreen.dart';
import 'discountScreen.dart';
import 'netSalaryScreen.dart';
import 'housingGoalScreen.dart';

class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF061A17) : const Color(0xFFF6F8F7);
    final isNarrow = MediaQuery.sizeOf(context).width < 390;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF064E3B),
        title: const Text(
          "Calculadoras",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.calculate_rounded, color: Colors.white, size: 34),
                SizedBox(height: 12),
                Text(
                  "Herramientas financieras",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Calcula, compara y planea tus decisiones de dinero desde un solo lugar.",
                  style: TextStyle(color: Colors.white70, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: isNarrow ? 1 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isNarrow ? 2.2 : 0.6,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: const [
              _CalculatorTile(
                title: "Calculadora rapida",
                subtitle: "Suma, divide y estima al instante.",
                metric: "Basica",
                icon: Icons.dialpad_rounded,
                color: Color(0xFF10B981),
                screen: SimpleCalculatorScreen(),
              ),
              _CalculatorTile(
                title: "Interes simple",
                subtitle: "Rendimiento lineal sobre capital.",
                metric: "Capital x tasa",
                icon: Icons.trending_up_rounded,
                color: Color(0xFF059669),
                screen: SimpleInterestScreen(),
              ),
              _CalculatorTile(
                title: "Interes compuesto",
                subtitle: "Ganancias reinvertidas en el tiempo.",
                metric: "Largo plazo",
                icon: Icons.show_chart_rounded,
                color: Color(0xFF2563EB),
                screen: CompoundInterestScreen(),
              ),
              _CalculatorTile(
                title: "Prestamos",
                subtitle: "Cuota mensual antes de endeudarte.",
                metric: "Credito",
                icon: Icons.account_balance_rounded,
                color: Color(0xFF7C3AED),
                screen: LoanScreen(),
              ),
              _CalculatorTile(
                title: "Ahorro",
                subtitle: "Convierte metas en cuotas mensuales.",
                metric: "Mensual",
                icon: Icons.savings_rounded,
                color: Color(0xFFF59E0B),
                screen: SavingsGoalScreen(),
              ),
              _CalculatorTile(
                title: "Inflacion",
                subtitle: "Proyecta precios y poder adquisitivo.",
                metric: "Proyeccion",
                icon: Icons.price_change_rounded,
                color: Color(0xFFEF4444),
                screen: InflationScreen(),
              ),
              _CalculatorTile(
                title: "Divisas",
                subtitle: "Convierte monedas en tiempo real.",
                metric: "API Global",
                icon: Icons.currency_exchange_rounded,
                color: const Color(0xFF14B8A6), // Teal
                screen: CurrencyScreen(),
              ),
              _CalculatorTile(
                title: "Descuentos",
                subtitle: "Calcula el precio final con rebajas.",
                metric: "Ahorro",
                icon: Icons.local_offer_rounded,
                color: const Color(0xFFF43F5E), // Rose
                screen: DiscountScreen(),
              ),
              _CalculatorTile(
                title: "Meta de Vivienda",
                subtitle: "Simula el ahorro para tu casa o apto.",
                metric: "Subsidios",
                icon: Icons.home_work_rounded,
                color: const Color(0xFF8B5CF6), // Violet
                screen: HousingGoalScreen(),
              ),
              _CalculatorTile(
                title: "Tarjetas & Cashback",
                subtitle: "Pago mínimo vs. 1 cuota.",
                metric: "Beneficios",
                icon: Icons.credit_card_rounded,
                color: const Color(0xFFF97316), // Orange
                screen: CreditCardScreen(),
              ),
              _CalculatorTile(
                title: "Salario Neto",
                subtitle: "Calcula tu sueldo libre de deducciones.",
                metric: "Liquidez",
                icon: Icons.request_quote_rounded,
                color: const Color(0xFF0EA5E9), // Sky Blue
                screen: NetSalaryScreen(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalculatorTile extends StatefulWidget {
  const _CalculatorTile({
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.icon,
    required this.color,
    required this.screen,
  });

  final String title;
  final String subtitle;
  final String metric;
  final IconData icon;
  final Color color;
  final Widget screen;

  @override
  State<_CalculatorTile> createState() => _CalculatorTileState();
}

class _CalculatorTileState extends State<_CalculatorTile> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _active = true),
      onExit: (_) => setState(() => _active = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _active = true),
        onTapCancel: () => setState(() => _active = false),
        onTapUp: (_) => setState(() => _active = false),
        child: AnimatedScale(
          scale: _active ? 1.035 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => widget.screen),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: _active
                    ? LinearGradient(
                        colors: [
                          widget.color.withOpacity(0.95),
                          widget.color.withOpacity(0.68),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _active
                    ? null
                    : (isDark ? const Color(0xFF10231E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.color.withOpacity(0.16)),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(_active ? 0.26 : 0.08),
                    blurRadius: _active ? 24 : 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),

              // 🔥 AQUI ESTA EL FIX REAL
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _active
                                      ? Colors.white.withOpacity(0.18)
                                      : widget.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(widget.icon,
                                    color:
                                        _active ? Colors.white : widget.color,
                                    size: 24),
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_forward_rounded,
                                  color: _active ? Colors.white : widget.color,
                                  size: 20),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _active
                                          ? Colors.white.withOpacity(0.18)
                                          : widget.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      widget.metric,
                                      style: TextStyle(
                                        color: _active
                                            ? Colors.white
                                            : widget.color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _active ? Colors.white : null,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  height: 1.12,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                widget.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _active
                                      ? Colors.white70
                                      : (isDark
                                          ? Colors.white60
                                          : Colors.black54),
                                  fontSize: 12,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleCalculatorScreen extends StatefulWidget {
  const SimpleCalculatorScreen({super.key});

  @override
  State<SimpleCalculatorScreen> createState() => _SimpleCalculatorScreenState();
}

class _SimpleCalculatorScreenState extends State<SimpleCalculatorScreen> {
  String _display = "0";
  double? _storedValue;
  String? _operator;
  bool _shouldResetDisplay = false;
  String _expression = "";

  List<String> _history = [];

  void _addToHistory(String operation) {
    setState(() {
      _history.insert(0, operation);
      if (_history.length > 10) {
        _history.removeLast();
      }
    });
  }

  void _press(String value) {
    setState(() {
      if (value == "C") {
        _display = "0";
        _expression = "";
        _storedValue = null;
        _operator = null;
        _shouldResetDisplay = false;
        return;
      }

      if (value == "DEL") {
        if (_display.length > 1) {
          _display = _display.substring(0, _display.length - 1);
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
        } else {
          _display = "0";
          _expression = "";
        }
        return;
      }

      if (["+", "-", "x", "/"].contains(value)) {
        _storedValue = double.tryParse(_display);
        _operator = value;
        _expression += " $value ";
        _shouldResetDisplay = true;
        return;
      }

      if (value == "=") {
        final current = double.tryParse(_display);
        if (_storedValue == null || current == null || _operator == null) {
          return;
        }

        double result = current;

        if (_operator == "+") {
          result = _storedValue! + current;
        } else if (_operator == "-") {
          result = _storedValue! - current;
        } else if (_operator == "x") {
          result = _storedValue! * current;
        } else if (_operator == "/") {
          result = current == 0 ? 0 : _storedValue! / current;
        }

        _addToHistory("$_expression = ${_format(result)}");

        _display = _format(result);
        _expression = "";
        _storedValue = null;
        _operator = null;
        _shouldResetDisplay = true;
        return;
      }

      if (value == "." && _display.contains(".") && !_shouldResetDisplay) {
        return;
      }

      if (_shouldResetDisplay) {
        _display = value;
        _expression += value;
      } else {
        _display = (_display == "0") ? value : "$_display$value";
        _expression += value;
      }

      _shouldResetDisplay = false;
    });
  }

  String _format(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  bool _isOperator(String value) => ["+", "-", "x", "/", "="].contains(value);

  Color _buttonBackgroundColor(String value) {
    if (value == "C") return const Color(0xFFEF4444);
    if (value == "DEL") return const Color(0xFFF59E0B);
    return _isOperator(value) ? const Color(0xFF10B981) : const Color(0xFF10231E);
  }

  Color _buttonForegroundColor(String value) {
    return value == "C" ? Colors.white : Colors.white;
  }

  bool _showHistory = false;

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      "C",
      "DEL",
      "/",
      "x",
      "7",
      "8",
      "9",
      "-",
      "4",
      "5",
      "6",
      "+",
      "1",
      "2",
      "3",
      "=",
      "0",
      ".",
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF061A17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text("Calculadora rapida"),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.expand_less : Icons.history),
            onPressed: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_showHistory)
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Historial",
                          style: TextStyle(color: Color.fromARGB(213, 221, 221, 221)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _history.clear();
                            });
                          },
                        )
                      ],
                    ),
                    Expanded(
                      child: ListView(
                        reverse: true,
                        children: _history
                            .map((e) => Text(
                                  e,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.right,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: Text(
                      _expression.isEmpty ? ' ' : _expression,
                      key: ValueKey(_expression),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: FittedBox(
                      key: ValueKey(_display),
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _display,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 58,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GridView.builder(
                itemCount: keys.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final key = keys[index];
                  final isAccent = ["+", "-", "x", "/", "="].contains(key);

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonBackgroundColor(key),
                      foregroundColor: _buttonForegroundColor(key),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.all(0),
                      textStyle: TextStyle(
                        fontSize: key == "DEL" ? 15 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ).copyWith(
                      overlayColor: MaterialStateProperty.all(
                        Colors.white.withOpacity(0.12),
                      ),
                    ),
                    onPressed: () => _press(key),
                    child: Center(
                      child: Text(key),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
