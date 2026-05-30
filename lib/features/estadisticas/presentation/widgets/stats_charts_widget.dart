import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/local_db/stats_stream_service.dart';
import '../../data/models/models.dart';
import '../../domain/services/stats_calculator.dart';

/// Widget de gráficos para visualizar estadísticas de voleibol
///
/// Incluye:
/// - Gráfico de barras: Puntos por jugador
/// - Gráfico de pastel: Errores vs Aciertos
///
/// Diseño: Tema oscuro moderno con acentos azul y naranja
class StatsChartsWidget extends StatelessWidget {
  /// Mapa de estadísticas por jugador
  final Map<int, PlayerStats> statsMap;
  
  /// Lista de jugadores
  final List<Player> jugadores;
  
  /// Título del widget
  final String titulo;

  const StatsChartsWidget({
    super.key,
    required this.statsMap,
    required this.jugadores,
    this.titulo = 'ESTADÍSTICAS',
  });

  // Colores del tema
  static const Color _primaryDark = Color(0xFF002B5B);
  static const Color _primaryLight = Color(0xFF0081CF);
  static const Color _accentOrange = Color(0xFFFF8C00);
  static const Color _backgroundDark = Color(0xFF0D1117);
  static const Color _surfaceDark = Color(0xFF161B22);
  static const Color _cardDark = Color(0xFF21262D);
  static const Color _successGreen = Color(0xFF2EA043);
  static const Color _errorRed = Color(0xFFF85149);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_backgroundDark, _surfaceDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Gráfico de barras
                  _buildBarChartSection(),
                  const SizedBox(height: 24),
                  // Gráfico de pastel
                  _buildPieChartSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryDark.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bar_chart,
            color: _accentOrange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartSection() {
    // Preparar datos para el gráfico
    final barData = <BarChartGroupData>[];
    final labels = <String>[];
    
    int index = 0;
    for (final jugador in jugadores) {
      final stats = statsMap[jugador.id];
      if (stats != null) {
        barData.add(
          BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: stats.puntosPositivos.toDouble(),
                color: _successGreen,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: _getMaxPoints() + 5,
                  color: _cardDark,
                ),
              ),
            ],
          ),
        );
        labels.add('#${jugador.numero ?? '—'}');
        index++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_volleyball, color: _successGreen, size: 18),
              const SizedBox(width: 8),
              const Text(
                'PUNTOS POR JUGADOR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: barData.isEmpty
                ? _buildEmptyState('Sin datos')
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxPoints() + 5,
                      barGroups: barData,
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < labels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    labels[idx],
                                    style: TextStyle(
                                      color: _primaryLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: _primaryDark,
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final jugador = jugadores[group.x.toInt()];
                            return BarTooltipItem(
                              '${jugador.nombre}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: '${rod.toY.toInt()} puntos',
                                  style: TextStyle(
                                    color: _successGreen,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection() {
    // Calcular totales
    int totalPositivos = 0;
    int totalNegativos = 0;

    for (final stats in statsMap.values) {
      totalPositivos += stats.puntosPositivos.toInt();
      totalNegativos += stats.errores.toInt();
    }

    final total = totalPositivos + totalNegativos;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: _accentOrange, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'ACIERTOS VS ERRORES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEmptyState('Sin datos'),
          ],
        ),
      );
    }

    final porcentajePositivos = (totalPositivos / total * 100).toStringAsFixed(1);
    final porcentajeNegativos = (totalNegativos / total * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: _accentOrange, size: 18),
              const SizedBox(width: 8),
              const Text(
                'ACIERTOS VS ERRORES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(
                          value: totalPositivos.toDouble(),
                          color: _successGreen,
                          title: '$porcentajePositivos%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          radius: 60,
                          badgeWidget: _buildBadge('✓', _successGreen),
                          badgePositionPercentageOffset: 1.3,
                        ),
                        PieChartSectionData(
                          value: totalNegativos.toDouble(),
                          color: _errorRed,
                          title: '$porcentajeNegativos%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          radius: 60,
                          badgeWidget: _buildBadge('✗', _errorRed),
                          badgePositionPercentageOffset: 1.3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      '✓ Acertados',
                      '$totalPositivos',
                      _successGreen,
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      '✗ Errores',
                      '$totalNegativos',
                      _errorRed,
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      'Total',
                      '$total',
                      _primaryLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxPoints() {
    double max = 0;
    for (final stats in statsMap.values) {
      if (stats.puntosPositivos > max) {
        max = stats.puntosPositivos.toDouble();
      }
    }
    return max > 0 ? max : 10;
  }
}
