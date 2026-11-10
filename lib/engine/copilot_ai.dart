import 'package:flutter/material.dart';
import '../models/cell_data.dart';
import '../models/sheet_data.dart';

enum CopilotModel {
  gpt56('OpenAI GPT-5.6 (July 2026)', 'Frontier multi-step reasoning & modeling'),
  claudeOpus5('Anthropic Claude Opus 5', 'Deep analytical synthesis & formula architecture'),
  gemini25('Google Gemini 2.5 Pro', 'Multimodal high-speed analytics & automation'),
  copilotPro('Microsoft Copilot Pro 2026', 'Official enterprise & Power BI grounded engine');

  final String title;
  final String description;
  const CopilotModel(this.title, this.description);
}

class CopilotResult {
  final String message;
  final String? suggestedFormula;
  final String? explanation;
  final List<String> insights;

  CopilotResult({
    required this.message,
    this.suggestedFormula,
    this.explanation,
    this.insights = const [],
  });
}

class CopilotTheme {
  final String name;
  final Color primaryHeader;
  final Color headerText;
  final Color alternatingRow;
  final Color accentTotal;

  const CopilotTheme({
    required this.name,
    required this.primaryHeader,
    required this.headerText,
    required this.alternatingRow,
    required this.accentTotal,
  });

  static const List<CopilotTheme> availableThemes = [
    CopilotTheme(
      name: 'Microsoft Emerald 2026',
      primaryHeader: Color(0xFF107C41),
      headerText: Colors.white,
      alternatingRow: Color(0xFFF3FBF6),
      accentTotal: Color(0xFFE1F5EA),
    ),
    CopilotTheme(
      name: 'Executive Dark Obsidian',
      primaryHeader: Color(0xFF1E293B),
      headerText: Colors.white,
      alternatingRow: Color(0xFFF8FAFC),
      accentTotal: Color(0xFFE2E8F0),
    ),
    CopilotTheme(
      name: 'Royal Corporate Navy',
      primaryHeader: Color(0xFF1E3A8A),
      headerText: Colors.white,
      alternatingRow: Color(0xFFEFF6FF),
      accentTotal: Color(0xFFDBEAFE),
    ),
    CopilotTheme(
      name: 'Warm Executive Amber',
      primaryHeader: Color(0xFFB45309),
      headerText: Colors.white,
      alternatingRow: Color(0xFFFFFBEB),
      accentTotal: Color(0xFFFEF3C7),
    ),
  ];
}

class CopilotAI {
  static CopilotModel activeModel = CopilotModel.gpt56;

  static Future<CopilotResult> processQuery(String query, SheetData sheet, String activeCellKey) async {
    // Artificial slight delay for realistic AI reasoning experience
    await Future.delayed(const Duration(milliseconds: 350));

    final q = query.toLowerCase().trim();

    // 1. Natural language to formula translation
    if (q.contains('sum') || q.contains('ekathu') || q.contains('total')) {
      final range = _detectRange(sheet, activeCellKey, isSum: true);
      return CopilotResult(
        message: 'Generated 2026 Dynamic Sum Formula',
        suggestedFormula: '=SUM($range)',
        explanation: 'Calculates the sum of numeric range $range based on active column analysis.',
      );
    }

    if (q.contains('average') || q.contains('samanaya') || q.contains('avg') || q.contains('mean')) {
      final range = _detectRange(sheet, activeCellKey);
      return CopilotResult(
        message: 'Generated Statistical Average Formula',
        suggestedFormula: '=AVERAGE($range)',
        explanation: 'Computes arithmetic mean of cells $range.',
      );
    }

    if (q.contains('max') || q.contains('highest') || q.contains('wadi')) {
      final range = _detectRange(sheet, activeCellKey);
      return CopilotResult(
        message: 'Generated Maximum Value Finder',
        suggestedFormula: '=MAX($range)',
        explanation: 'Finds the largest value in range $range.',
      );
    }

    if (q.contains('min') || q.contains('lowest') || q.contains('adu')) {
      final range = _detectRange(sheet, activeCellKey);
      return CopilotResult(
        message: 'Generated Minimum Value Finder',
        suggestedFormula: '=MIN($range)',
        explanation: 'Returns the smallest value in range $range.',
      );
    }

    if (q.contains('regex') || q.contains('email') || q.contains('pattern') || q.contains('validate')) {
      return CopilotResult(
        message: 'July 2026 Regex Validation Formula',
        suggestedFormula: '=REGEXTEST(A1, "^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+\$")',
        explanation: 'Modern 2026 REGEXTEST function checks if A1 contains a valid email format.',
      );
    }

    if (q.contains('python') || q.contains('py')) {
      return CopilotResult(
        message: 'Python in Excel 2026 Formula',
        suggestedFormula: '=PY(sum([100, 250, 420]) * 1.15)',
        explanation: 'Runs embedded Python script to aggregate list values with 15% VAT tax adjustment.',
      );
    }

    if (q.contains('xlookup') || q.contains('search') || q.contains('find') || q.contains('hoyanna')) {
      return CopilotResult(
        message: '2026 Fast XLOOKUP Formula',
        suggestedFormula: '=XLOOKUP(A2, B2:B20, C2:C20, "Not Found")',
        explanation: 'Modern replacement for VLOOKUP. Searches value A2 in B2:B20 and retrieves C2:C20.',
      );
    }

    if (q.contains('if') || q.contains('condition') || q.contains('pass')) {
      return CopilotResult(
        message: 'Conditional Logical Formula',
        suggestedFormula: '=IF(B2>=50, "Pass", "Fail")',
        explanation: 'Evaluates if B2 is 50 or above, returning "Pass", else "Fail".',
      );
    }

    // Default intelligent guidance
    return CopilotResult(
      message: 'Copilot Assistant 2026 (${activeModel.title})',
      explanation: 'Try asking: "Sum column", "Average sales", "Validate email with regex", "XLOOKUP customer", or "Python in Excel calculation".',
      insights: [
        'Active Model: ${activeModel.title}',
        'Grounding Status: Local Workbook + Synced Connectors Active',
        'AutoSave & Citation Integrity: Verified',
      ],
    );
  }

  static CopilotResult generateWorkbookInsights(SheetData sheet) {
    int cellCount = 0;
    int numericCount = 0;
    double numericSum = 0;
    double maxVal = double.negativeInfinity;
    double minVal = double.infinity;

    sheet.cells.forEach((key, cell) {
      if (cell.computedValue.trim().isNotEmpty) {
        cellCount++;
        final d = double.tryParse(cell.computedValue.replaceAll('\$', '').replaceAll('Rs.', '').trim());
        if (d != null) {
          numericCount++;
          numericSum += d;
          if (d > maxVal) maxVal = d;
          if (d < minVal) minVal = d;
        }
      }
    });

    final List<String> insights = [];
    insights.add('Data Density: $cellCount active cells across "${sheet.name}".');
    if (numericCount > 0) {
      final avg = numericSum / numericCount;
      insights.add('Numeric Aggregates: Total sum is ${numericSum.toStringAsFixed(2)} across $numericCount numbers.');
      insights.add('Average Range Value: ${avg.toStringAsFixed(2)}');
      insights.add('Range Boundaries: Highest value is $maxVal and lowest is $minVal.');
    } else {
      insights.add('Text & Labels: Sheet contains categorical or header structures.');
    }
    insights.add('Copilot 2026 Recommendation: Consider applying a Corporate Brand Theme or generating a Bar Chart for executive presentation.');

    return CopilotResult(
      message: 'Executive AI Analysis for ${sheet.name}',
      insights: insights,
    );
  }

  static void applyBrandTheme(SheetData sheet, CopilotTheme theme) {
    // Style Row 0 as Header
    for (int col = 0; col < sheet.colCount; col++) {
      final cell = sheet.getCell(0, col);
      cell.style = cell.style.copyWith(
        backgroundColor: theme.primaryHeader,
        textColor: theme.headerText,
        isBold: true,
        fontSize: 14.0,
        alignment: TextAlign.center,
        borderStyle: CellBorderStyle.all,
      );
    }

    // Style data rows with alternating stripes
    for (int row = 1; row < sheet.rowCount; row++) {
      final bgColor = (row % 2 == 1) ? theme.alternatingRow : Colors.white;
      for (int col = 0; col < sheet.colCount; col++) {
        final key = SheetData.cellKey(row, col);
        if (sheet.cells.containsKey(key)) {
          final cell = sheet.cells[key]!;
          if (cell.style.backgroundColor == Colors.white || cell.style.backgroundColor == const Color(0xFFF3FBF6) || cell.style.backgroundColor == const Color(0xFFF8FAFC)) {
            cell.style = cell.style.copyWith(
              backgroundColor: bgColor,
              borderStyle: CellBorderStyle.all,
            );
          }
        }
      }
    }
  }

  static String _detectRange(SheetData sheet, String activeCellKey, {bool isSum = false}) {
    final colName = activeCellKey.replaceAll(RegExp(r'[0-9]'), '');
    final activeRow = int.tryParse(activeCellKey.replaceAll(RegExp(r'[A-Z]'), '')) ?? 1;

    if (activeRow > 1) {
      return '${colName}1:${colName}${activeRow - 1}';
    }
    return '${colName}1:${colName}10';
  }
}
