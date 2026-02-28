import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../data/models/statistics_dashboard_data.dart' as dashboard;

/// Card widget displaying pie chart for app usage distribution
class PieChartCard extends StatefulWidget {
  final List<dashboard.PieChartData> data;
  final EdgeInsetsGeometry margin;

  const PieChartCard({
    super.key,
    required this.data,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  State<PieChartCard> createState() => _PieChartCardState();
}

class _PieChartCardState extends State<PieChartCard> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.data.isEmpty) {
      return _buildEmptyState(context);
    }

    return Card(
      elevation: 2,
      margin: widget.margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.pie_chart_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'توزيع استخدام التطبيقات',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pie Chart
            Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: _generateSections(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Legend below the chart
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateSections() {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 65.0 : 55.0;
      final fontSize = isTouched ? 14.0 : 11.0;

      return PieChartSectionData(
        color: data.color,
        value: data.timeInMillis.toDouble(),
        title: '${data.percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Colors.black45,
              blurRadius: 3,
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);

    // Show only top 5 apps in legend
    final displayData = widget.data.take(5).toList();

    return Column(
      children: displayData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final isTouched = touchedIndex == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                touchedIndex = isTouched ? -1 : index;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isTouched
                    ? data.color.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  // Color indicator (circle)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: data.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // App name
                  Expanded(
                    child: Text(
                      data.appName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isTouched ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Time
                  Text(
                    data.formattedTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Percentage
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: data.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${data.percentage.toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: data.color,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: widget.margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد بيانات',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'توزيع استخدام التطبيقات هيظهر هنا',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
