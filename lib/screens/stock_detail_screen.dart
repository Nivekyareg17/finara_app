import 'package:finara_app_v1/widgets/translate_widget.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/stock_model.dart';
import '../services/stock_service.dart';

class StockDetailScreen extends StatefulWidget {
  final Stock stock;

  const StockDetailScreen({super.key, required this.stock});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  String selectedRange = "1W";

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    final isUp = stock.change >= 0;

    // Colores dinámicos y premium
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isUp ? const Color(0xFF00D4AA) : const Color(0xFFFF4D4D);
    final bgColor = isDark ? const Color(0xFF060B14) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.white54 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          stock.symbol,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. HERO SECTION (PRECIO Y CAMBIO) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "\$${stock.price.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.1,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isUp ? Icons.show_chart : Icons.stacked_line_chart,
                              color: primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${isUp ? '+' : ''}${stock.percent.toStringAsFixed(2)}%",
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${isUp ? '+' : ''}\$${stock.change.toStringAsFixed(2)} Hoy",
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ─── 2. GRÁFICA INTERACTIVA PREMIUM ───
            FutureBuilder<List<double>>(
              future: StockService().getHistory(stock.symbol, selectedRange),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 280,
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox(
                    height: 280,
                    child: Center(child: Text("Datos no disponibles")),
                  );
                }

                final prices = snapshot.data!;
                final minY = prices.reduce((a, b) => a < b ? a : b);
                final maxY = prices.reduce((a, b) => a > b ? a : b);
                final yPadding = (maxY - minY) * 0.15; 

                return SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: LineChart(
                    LineChartData(
                      minY: minY - yPadding,
                      maxY: maxY + yPadding,
                      
                      // LÍNEAS GUÍA PUNTEADAS (GRID SUTIL)
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (maxY - minY) / 4 > 0 ? (maxY - minY) / 4 : 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: mutedColor.withOpacity(0.15),
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      
                      // PRECIOS LATERALES DERECHOS
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.max || value == meta.min) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  "\$${value.toStringAsFixed(1)}",
                                  style: TextStyle(color: mutedColor, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      borderData: FlBorderData(show: false),
                      
                      // PUNTERO Y TOOLTIP
                      lineTouchData: LineTouchData(
                        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                          return spotIndexes.map((spotIndex) {
                            return TouchedSpotIndicatorData(
                              FlLine(color: mutedColor.withOpacity(0.5), strokeWidth: 1.5, dashArray: [4, 4]),
                              FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 5,
                                    color: primaryColor,
                                    strokeWidth: 3,
                                    strokeColor: bgColor,
                                  );
                                },
                              ),
                            );
                          }).toList();
                        },
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => cardColor,
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                "\$${spot.y.toStringAsFixed(2)}",
                                TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        handleBuiltInTouches: true,
                      ),
                      
                      // LÍNEA PRINCIPAL CON SOMBRA (GLOW)
                      lineBarsData: [
                        LineChartBarData(
                          spots: prices.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value);
                          }).toList(),
                          isCurved: true,
                          color: primaryColor,
                          barWidth: 3.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          shadow: Shadow(
                            color: primaryColor.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.25),
                                primaryColor.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ─── 3. SELECTOR DE RANGOS DE TIEMPO ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ["1D", "1W", "1M", "3M", "1Y"].map((range) {
                    final isSelected = selectedRange == range;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedRange = range),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? cardColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            range,
                            style: TextStyle(
                              color: isSelected ? textColor : mutedColor,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ─── 4. ESTADÍSTICAS DEL ACTIVO ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TranslatedText(
                    "Estadísticas clave",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Apertura",
                          "\$${(stock.price - stock.change).toStringAsFixed(2)}",
                          cardColor,
                          textColor,
                          mutedColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          "Vol. Diario",
                          "1.2M", 
                          cardColor,
                          textColor,
                          mutedColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Máx. 52 Semanas",
                          "\$${(stock.price * 1.15).toStringAsFixed(2)}", 
                          cardColor,
                          textColor,
                          mutedColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          "Mín. 52 Semanas",
                          "\$${(stock.price * 0.85).toStringAsFixed(2)}", 
                          cardColor,
                          textColor,
                          mutedColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para las tarjetas de estadísticas
  Widget _buildStatCard(String label, String value, Color bgColor, Color textColor, Color mutedColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mutedColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: mutedColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}