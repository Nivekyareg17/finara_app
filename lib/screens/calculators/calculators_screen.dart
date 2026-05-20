import 'package:flutter/material.dart';
import 'compound_interest_screen.dart';
import 'inflation_screen.dart';
import 'loan_screen.dart';
import 'savings_goal_screen.dart';
import 'simple_interest_screen.dart';

class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF061A17) : const Color(0xFFF6F8F7);

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
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.88,
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
            ],
          ),
        ],
      ),
    );
  }
}

class _CalculatorTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF10231E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_rounded, color: color, size: 20),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                metric,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
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

  void _press(String value) {
    setState(() {
      if (value == "C") {
        _display = "0";
        _storedValue = null;
        _operator = null;
        _shouldResetDisplay = false;
        return;
      }

      if (value == "DEL") {
        _display = _display.length > 1
            ? _display.substring(0, _display.length - 1)
            : "0";
        return;
      }

      if (["+", "-", "x", "/"].contains(value)) {
        _storedValue = double.tryParse(_display);
        _operator = value;
        _shouldResetDisplay = true;
        return;
      }

      if (value == "=") {
        final current = double.tryParse(_display);
        if (_storedValue == null || current == null || _operator == null) {
          return;
        }
        final result = switch (_operator) {
          "+" => _storedValue! + current,
          "-" => _storedValue! - current,
          "x" => _storedValue! * current,
          "/" => current == 0 ? 0 : _storedValue! / current,
          _ => current,
        };
        _display = _format(result);
        _storedValue = null;
        _operator = null;
        _shouldResetDisplay = true;
        return;
      }

      if (value == "." && _display.contains(".") && !_shouldResetDisplay) {
        return;
      }
      _display =
          (_display == "0" || _shouldResetDisplay) ? value : "$_display$value";
      _shouldResetDisplay = false;
    });
  }

  String _format(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: FittedBox(
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
              ),
            ),
            const SizedBox(height: 18),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
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
                    backgroundColor: isAccent
                        ? const Color(0xFF10B981)
                        : const Color(0xFF10231E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _press(key),
                  child: Text(
                    key,
                    style: TextStyle(
                      fontSize: key == "DEL" ? 15 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
