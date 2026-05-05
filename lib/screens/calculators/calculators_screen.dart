import 'package:flutter/material.dart';
import 'simple_interest_screen.dart';
import 'compound_interest_screen.dart';
import 'loan_screen.dart';
import 'savings_goal_screen.dart';
import 'inflation_screen.dart';

class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  void _showGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Guía de calculadoras",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  "📊 Interés simple",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Se usa cuando el interés no cambia con el tiempo. Ideal para cálculos rápidos.",
                ),
                SizedBox(height: 12),
                Text(
                  "📈 Interés compuesto",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Aquí los intereses generan más intereses. Es clave para inversiones y ahorro.",
                ),
                SizedBox(height: 12),
                Text(
                  "🏦 Préstamos",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Calcula cuánto pagarás cada mes en un crédito o préstamo.",
                ),
                SizedBox(height: 12),
                Text(
                  "💰 Ahorro",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Te ayuda a saber cuánto debes ahorrar para alcanzar una meta.",
                ),
                SizedBox(height: 12),
                Text(
                  "📉 Inflación",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Muestra cómo el dinero pierde valor con el tiempo.",
                ),
                SizedBox(height: 20),
                Text(
                  "💡 Consejo",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Usa estas herramientas para tomar mejores decisiones financieras y planificar tu futuro.",
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calculadoras")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _card(context, "Interés simple", Icons.trending_up,
                const SimpleInterestScreen()),
            _card(context, "Interés compuesto", Icons.show_chart,
                const CompoundInterestScreen()),
            _card(context, "Préstamos", Icons.account_balance,
                const LoanScreen()),
            _card(context, "Ahorro", Icons.savings, const SavingsGoalScreen()),
            _card(context, "Inflación", Icons.attach_money,
                const InflationScreen()),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "¿No sabes por dónde empezar?",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showGuide(context),
              icon: const Icon(Icons.menu_book),
              label: const Text("Guía financiera"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
      BuildContext context, String title, IconData icon, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.green),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, String title, Widget screen) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
      ),
    );
  }
}
