import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/sheet_data.dart';

enum ChartType {
  bar('Bar Chart', Icons.bar_chart),
  line('Line Chart', Icons.show_chart),
  pie('Pie Chart', Icons.pie_chart);

  final String title;
  final IconData icon;
  const ChartType(this.title, this.icon);
}

class ChartDataPoint {
  final String label;
  final double value;
  final Color color;

  ChartDataPoint(this.label, this.value, this.color);
}

class ChartViewDialog extends StatefulWidget {
  final SheetData sheet;

  const ChartViewDialog({super.key, required this.sheet});

  @override
  State<ChartViewDialog> createState() => _ChartViewDialogState();
}

class _ChartViewDialogState extends State<ChartViewDialog> {
  ChartType _selectedType = ChartType.bar;
  List<ChartDataPoint> _dataPoints = [];

  final List<Color> _palette = const [
    Color(0xFF107C41),
    Color(0xFF1E3A8A),
    Color(0xFFD97706),
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
    Color(0xFF0D9488),
    Color(0xFFEA580C),
    Color(0xFF4F46E5),
  ];

  @override
  void initState() {
    super.initState();
    _extractData();
  }

  void _extractData() {
    final points = <ChartDataPoint>[];
    // Look for first column of text (labels) and next column of numbers (values)
    int labelCol = 0;
    int valueCol = 1;

    for (int r = 1; r < math.min(12, widget.sheet.rowCount); r++) {
      final labelCell = widget.sheet.getCell(r, labelCol);
      final valueCell = widget.sheet.getCell(r, valueCol);

      final label = labelCell.computedValue.trim();
      final valStr = valueCell.computedValue.replaceAll('\$', '').replaceAll('Rs.', '').replaceAll(',', '').trim();
      final numVal = double.tryParse(valStr);

      if (label.isNotEmpty && numVal != null && numVal > 0) {
        final color = _palette[points.length % _palette.length];
        points.add(ChartDataPoint(label, numVal, color));
      }
    }

    if (points.isEmpty) {
      // Fallback demo points
      points.add(ChartDataPoint('Item A', 450, _palette[0]));
      points.add(ChartDataPoint('Item B', 720, _palette[1]));
      points.add(ChartDataPoint('Item C', 310, _palette[2]));
      points.add(ChartDataPoint('Item D', 580, _palette[3]));
      points.add(ChartDataPoint('Item E', 890, _palette[4]));
    }

    setState(() {
      _dataPoints = points;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_rounded, color: Color(0xFF107C41), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Green Excel 2026 Visualizer',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Sheet: ${widget.sheet.name} (Auto Data Range)',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            // Chart Type Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ChartType.values.map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    avatar: Icon(type.icon, size: 16, color: isSelected ? Colors.white : Colors.black87),
                    label: Text(type.title),
                    selected: isSelected,
                    selectedColor: const Color(0xFF107C41),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedType = type);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Chart Canvas
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.all(12),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _ExcelChartPainter(
                    type: _selectedType,
                    data: _dataPoints,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: _dataPoints.map((pt) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, color: pt.color),
                    const SizedBox(width: 4),
                    Text('${pt.label}: ${pt.value.toInt()}', style: const TextStyle(fontSize: 10)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExcelChartPainter extends CustomPainter {
  final ChartType type;
  final List<ChartDataPoint> data;

  _ExcelChartPainter({required this.type, required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    switch (type) {
      case ChartType.bar:
        _drawBarChart(canvas, size);
        break;
      case ChartType.line:
        _drawLineChart(canvas, size);
        break;
      case ChartType.pie:
        _drawPieChart(canvas, size);
        break;
    }
  }

  void _drawBarChart(Canvas canvas, Size size) {
    final double maxVal = data.map((e) => e.value).reduce(math.max);
    final double padLeft = 40;
    final double padBottom = 30;
    final double chartW = size.width - padLeft - 10;
    final double chartH = size.height - padBottom - 10;

    // Draw Gridlines
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = chartH - (chartH / 4) * i + 10;
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - 10, y), gridPaint);
      final labelVal = (maxVal / 4 * i).toInt().toString();
      final tp = TextPainter(
        text: TextSpan(text: labelVal, style: TextStyle(color: Colors.grey.shade600, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padLeft - tp.width - 4, y - tp.height / 2));
    }

    // Draw Bars
    final barWidth = (chartW / data.length) * 0.6;
    final step = chartW / data.length;

    for (int i = 0; i < data.length; i++) {
      final pt = data[i];
      final barH = (pt.value / maxVal) * chartH;
      final x = padLeft + (i * step) + (step - barWidth) / 2;
      final y = chartH - barH + 10;

      final barPaint = Paint()..color = pt.color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barH),
          const Radius.circular(4),
        ),
        barPaint,
      );

      // Label below bar
      final tp = TextPainter(
        text: TextSpan(text: pt.label, style: const TextStyle(color: Colors.black87, fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: step);
      tp.paint(canvas, Offset(x + (barWidth - tp.width) / 2, chartH + 14));
    }
  }

  void _drawLineChart(Canvas canvas, Size size) {
    final double maxVal = data.map((e) => e.value).reduce(math.max);
    final double padLeft = 40;
    final double padBottom = 30;
    final double chartW = size.width - padLeft - 10;
    final double chartH = size.height - padBottom - 10;

    // Line Path
    final path = Path();
    final step = chartW / (data.length - 1 == 0 ? 1 : data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = padLeft + (i * step);
      final y = chartH - (data[i].value / maxVal) * chartH + 10;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = const Color(0xFF107C41)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Draw Dots
    for (int i = 0; i < data.length; i++) {
      final x = padLeft + (i * step);
      final y = chartH - (data[i].value / maxVal) * chartH + 10;
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = data[i].color);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
    }
  }

  void _drawPieChart(Canvas canvas, Size size) {
    final double total = data.fold<double>(0.0, (p, e) => p + e.value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;

    double startAngle = -math.pi / 2;
    for (final pt in data) {
      final sweepAngle = (pt.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = pt.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
