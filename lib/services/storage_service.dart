import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/cell_data.dart';
import '../models/sheet_data.dart';
import '../engine/formula_evaluator.dart';

class StorageService {
  static const String _prefKeyWorkbook = 'green_excel_active_workbook_v1';

  static Future<void> saveWorkbook(Workbook workbook) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(workbook.toJson());
    await prefs.setString(_prefKeyWorkbook, jsonStr);
  }

  static Future<Workbook?> loadWorkbook() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKeyWorkbook);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        final wb = Workbook.fromJson(data);
        for (final s in wb.sheets) {
          FormulaEvaluator.evaluateAll(s);
        }
        return wb;
      }
    } catch (_) {}
    return null;
  }

  static String exportSheetToCsv(SheetData sheet) {
    int maxR = 0;
    int maxC = 0;
    sheet.cells.forEach((key, cell) {
      if (cell.computedValue.trim().isNotEmpty || cell.isCheckbox) {
        final colName = key.replaceAll(RegExp(r'[0-9]'), '');
        final rowNum = int.tryParse(key.replaceAll(RegExp(r'[A-Z]'), '')) ?? 1;
        final c = SheetData.colNameToIndex(colName);
        final r = rowNum - 1;
        if (r > maxR) maxR = r;
        if (c > maxC) maxC = c;
      }
    });

    final sb = StringBuffer();
    for (int r = 0; r <= maxR; r++) {
      final rowItems = <String>[];
      for (int c = 0; c <= maxC; c++) {
        final cell = sheet.getCell(r, c);
        String val = cell.isCheckbox
            ? (cell.checked ? 'TRUE' : 'FALSE')
            : (cell.isFormula ? cell.rawValue : cell.computedValue);
        // Escape quotes
        if (val.contains(',') || val.contains('"') || val.contains('\n')) {
          val = '"${val.replaceAll('"', '""')}"';
        }
        rowItems.add(val);
      }
      sb.writeln(rowItems.join(','));
    }
    return sb.toString();
  }

  static Future<void> shareCsv(SheetData sheet) async {
    final csvContent = exportSheetToCsv(sheet);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${sheet.name}_export.csv');
    await file.writeAsString(csvContent);
    await Share.shareXFiles([XFile(file.path)], text: 'Exported from Green Excel 2026 Pro');
  }

  static void importCsvToSheet(String csvText, SheetData sheet) {
    final lines = csvText.split('\n');
    for (int r = 0; r < lines.length && r < sheet.rowCount; r++) {
      final line = lines[r].trim();
      if (line.isEmpty) continue;
      final cols = _parseCsvLine(line);
      for (int c = 0; c < cols.length && c < sheet.colCount; c++) {
        final val = cols[c].trim();
        final cell = sheet.getCell(r, c);
        if (val.toUpperCase() == 'TRUE' || val.toUpperCase() == 'FALSE') {
          cell.isCheckbox = true;
          cell.checked = val.toUpperCase() == 'TRUE';
          cell.rawValue = val;
        } else {
          cell.rawValue = val;
        }
      }
    }
    FormulaEvaluator.evaluateAll(sheet);
  }

  static List<String> _parseCsvLine(String line) {
    final list = <String>[];
    final sb = StringBuffer();
    bool inQuote = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuote && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++;
        } else {
          inQuote = !inQuote;
        }
      } else if (ch == ',' && !inQuote) {
        list.add(sb.toString());
        sb.clear();
      } else {
        sb.write(ch);
      }
    }
    list.add(sb.toString());
    return list;
  }

  // Pre-loaded 2026 Templates
  static Workbook createBudgetTemplate() {
    final sheet = SheetData(name: 'Budget 2026');

    void set(int r, int c, String val, {bool isBold = false, Color? bg, Color? fg, CellNumberFormat fmt = CellNumberFormat.general, bool isCheck = false, bool checked = false}) {
      final cell = sheet.getCell(r, c);
      cell.rawValue = val;
      cell.isCheckbox = isCheck;
      cell.checked = checked;
      cell.style = cell.style.copyWith(
        isBold: isBold,
        backgroundColor: bg ?? Colors.white,
        textColor: fg ?? const Color(0xFF212529),
        numberFormat: fmt,
        borderStyle: CellBorderStyle.all,
      );
    }

    // Header
    const headerBg = Color(0xFF107C41);
    set(0, 0, 'Expense Category', isBold: true, bg: headerBg, fg: Colors.white);
    set(0, 1, 'Projected (\$)', isBold: true, bg: headerBg, fg: Colors.white);
    set(0, 2, 'Actual (\$)', isBold: true, bg: headerBg, fg: Colors.white);
    set(0, 3, 'Difference (\$)', isBold: true, bg: headerBg, fg: Colors.white);
    set(0, 4, 'Paid (2026 Checkbox)', isBold: true, bg: headerBg, fg: Colors.white);

    // Rows
    final items = [
      ['Office Rent', '2500', '2500', '=B2-C2', 'true'],
      ['Cloud Servers', '1200', '1150', '=B3-C3', 'true'],
      ['Hardware R&D', '3400', '3600', '=B4-C4', 'false'],
      ['Marketing', '1500', '1400', '=B5-C5', 'true'],
      ['Software Licenses', '800', '800', '=B6-C6', 'false'],
    ];

    for (int i = 0; i < items.length; i++) {
      final r = i + 1;
      final row = items[i];
      final bg = (r % 2 == 1) ? const Color(0xFFF3FBF6) : Colors.white;
      set(r, 0, row[0], bg: bg);
      set(r, 1, row[1], fmt: CellNumberFormat.currencyUSD, bg: bg);
      set(r, 2, row[2], fmt: CellNumberFormat.currencyUSD, bg: bg);
      set(r, 3, row[3], fmt: CellNumberFormat.currencyUSD, bg: bg);
      set(r, 4, row[4].toUpperCase(), isCheck: true, checked: row[4] == 'true', bg: bg);
    }

    // Total Row
    set(6, 0, 'TOTAL', isBold: true, bg: const Color(0xFFE1F5EA));
    set(6, 1, '=SUM(B2:B6)', isBold: true, fmt: CellNumberFormat.currencyUSD, bg: const Color(0xFFE1F5EA));
    set(6, 2, '=SUM(C2:C6)', isBold: true, fmt: CellNumberFormat.currencyUSD, bg: const Color(0xFFE1F5EA));
    set(6, 3, '=SUM(D2:D6)', isBold: true, fmt: CellNumberFormat.currencyUSD, bg: const Color(0xFFE1F5EA));
    set(6, 4, '', bg: const Color(0xFFE1F5EA));

    FormulaEvaluator.evaluateAll(sheet);
    return Workbook(title: 'Monthly_Budget_2026', sheets: [sheet]);
  }

  static Workbook createSalesTemplate() {
    final sheet = SheetData(name: 'Sales Dashboard');

    void set(int r, int c, String val, {bool isBold = false, Color? bg, Color? fg, CellNumberFormat fmt = CellNumberFormat.general}) {
      final cell = sheet.getCell(r, c);
      cell.rawValue = val;
      cell.style = cell.style.copyWith(
        isBold: isBold,
        backgroundColor: bg ?? Colors.white,
        textColor: fg ?? const Color(0xFF212529),
        numberFormat: fmt,
        borderStyle: CellBorderStyle.all,
      );
    }

    const headerBg = Color(0xFF1E3A8A);
    set(0, 0, 'Product Item', isBold: true, bg: headerBg, fg: Colors.white);
    set(0, 1, 'Units Sold', isBold: true, bg: headerBg, fg: Colors.white);
    set(0, 2, 'Unit Price', isBold: true, bg: headerBg, fg: Colors.white);
    set(0, 3, 'Revenue (Total)', isBold: true, bg: headerBg, fg: Colors.white);
    set(0, 4, 'Profit (15% Net)', isBold: true, bg: headerBg, fg: Colors.white);

    final products = [
      ['Microcontroller Board', '140', '25', '=B2*C2', '=D2*0.15'],
      ['Green Smart Sensor', '320', '18', '=B3*C3', '=D3*0.15'],
      ['Embedded Display 7"', '85', '65', '=B4*C4', '=D4*0.15'],
      ['Power Supply Module', '210', '14', '=B5*C5', '=D5*0.15'],
      ['IoT Gateway Device', '60', '120', '=B6*C6', '=D6*0.15'],
    ];

    for (int i = 0; i < products.length; i++) {
      final r = i + 1;
      final p = products[i];
      final bg = (r % 2 == 1) ? const Color(0xFFEFF6FF) : Colors.white;
      set(r, 0, p[0], bg: bg);
      set(r, 1, p[1], fmt: CellNumberFormat.number, bg: bg);
      set(r, 2, p[2], fmt: CellNumberFormat.currencyUSD, bg: bg);
      set(r, 3, p[3], fmt: CellNumberFormat.currencyUSD, bg: bg);
      set(r, 4, p[4], fmt: CellNumberFormat.currencyUSD, bg: bg);
    }

    set(6, 0, 'TOTAL REVENUE', isBold: true, bg: const Color(0xFFDBEAFE));
    set(6, 1, '=SUM(B2:B6)', isBold: true, bg: const Color(0xFFDBEAFE));
    set(6, 2, '=AVERAGE(C2:C6)', isBold: true, fmt: CellNumberFormat.currencyUSD, bg: const Color(0xFFDBEAFE));
    set(6, 3, '=SUM(D2:D6)', isBold: true, fmt: CellNumberFormat.currencyUSD, bg: const Color(0xFFDBEAFE));
    set(6, 4, '=SUM(E2:E6)', isBold: true, fmt: CellNumberFormat.currencyUSD, bg: const Color(0xFFDBEAFE));

    FormulaEvaluator.evaluateAll(sheet);
    return Workbook(title: 'Sales_Inventory_2026', sheets: [sheet]);
  }
}
