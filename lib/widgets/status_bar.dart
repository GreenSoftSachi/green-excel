import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sheet_data.dart';

class ExcelStatusBar extends StatelessWidget {
  final RangeStats stats;
  final bool isAutoSaved;
  final String activeRangeText;

  const ExcelStatusBar({
    super.key,
    required this.stats,
    required this.isAutoSaved,
    required this.activeRangeText,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0.00');

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF107C41),
        border: Border(top: BorderSide(color: Colors.green.shade900, width: 0.5)),
      ),
      child: Row(
        children: [
          // Left: Ready Status & Range Name
          Row(
            children: [
              const Icon(Icons.circle, size: 7, color: Color(0xFF86EFAC)),
              const SizedBox(width: 5),
              const Text(
                'Ready',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  activeRangeText,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Right: Real-Time Dynamic Excel Calculations (SUM, AVERAGE, COUNT)
          if (stats.count > 0) ...[
            if (stats.numericCount > 1) ...[
              _statItem('AVERAGE', currencyFmt.format(stats.average)),
              _vDivider(),
            ],
            _statItem('COUNT', stats.count.toString()),
            if (stats.numericCount > 0) ...[
              _vDivider(),
              _statItem('SUM', currencyFmt.format(stats.sum)),
            ],
            _vDivider(),
          ],

          // Zoom & View
          Row(
            children: [
              Icon(Icons.remove, size: 12, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 4),
              const Text(
                '100%',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Icon(Icons.add, size: 12, color: Colors.white.withOpacity(0.8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withOpacity(0.3),
    );
  }
}
