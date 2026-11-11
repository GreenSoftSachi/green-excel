import 'dart:math' as math;
import 'cell_data.dart';

class CellRange {
  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;

  const CellRange({
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
  });

  int get minRow => math.min(startRow, endRow);
  int get maxRow => math.max(startRow, endRow);
  int get minCol => math.min(startCol, endCol);
  int get maxCol => math.max(startCol, endCol);

  bool contains(int row, int col) {
    return row >= minRow && row <= maxRow && col >= minCol && col <= maxCol;
  }

  bool isSingleCell() => minRow == maxRow && minCol == maxCol;

  String toRangeString() {
    final startKey = SheetData.cellKey(minRow, minCol);
    if (isSingleCell()) return startKey;
    final endKey = SheetData.cellKey(maxRow, maxCol);
    return '$startKey:$endKey';
  }
}

class RangeStats {
  final int count;
  final int numericCount;
  final double sum;
  final double average;
  final double min;
  final double max;

  const RangeStats({
    this.count = 0,
    this.numericCount = 0,
    this.sum = 0,
    this.average = 0,
    this.min = 0,
    this.max = 0,
  });
}

class SheetData {
  String name;
  Map<String, CellData> cells;
  int rowCount;
  int colCount;

  SheetData({
    required this.name,
    Map<String, CellData>? cells,
    this.rowCount = 60,
    this.colCount = 26,
  }) : cells = cells ?? {};

  static String indexToColName(int index) {
    String result = '';
    int temp = index;
    while (temp >= 0) {
      result = String.fromCharCode((temp % 26) + 65) + result;
      temp = (temp ~/ 26) - 1;
    }
    return result;
  }

  static int colNameToIndex(String colName) {
    int sum = 0;
    for (int i = 0; i < colName.length; i++) {
      sum = sum * 26 + (colName.codeUnitAt(i) - 65 + 1);
    }
    return sum - 1;
  }

  static String cellKey(int row, int col) {
    return '${indexToColName(col)}${row + 1}';
  }

  CellData getCell(int row, int col) {
    final key = cellKey(row, col);
    return cells.putIfAbsent(key, () => CellData());
  }

  CellData? getCellByKey(String key) {
    final normalized = key.toUpperCase().trim();
    return cells[normalized];
  }

  void setCell(int row, int col, CellData cell) {
    final key = cellKey(row, col);
    cells[key] = cell;
  }

  RangeStats computeRangeStats(CellRange range) {
    int count = 0;
    int numericCount = 0;
    double sum = 0;
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;

    for (int r = range.minRow; r <= range.maxRow; r++) {
      for (int c = range.minCol; c <= range.maxCol; c++) {
        final key = cellKey(r, c);
        if (cells.containsKey(key)) {
          final cell = cells[key]!;
          if (cell.computedValue.trim().isNotEmpty) {
            count++;
            final valStr = cell.computedValue
                .replaceAll('\$', '')
                .replaceAll('Rs.', '')
                .replaceAll(',', '')
                .trim();
            final numVal = double.tryParse(valStr);
            if (numVal != null) {
              numericCount++;
              sum += numVal;
              if (numVal < minVal) minVal = numVal;
              if (numVal > maxVal) maxVal = numVal;
            }
          }
        }
      }
    }

    final avg = numericCount > 0 ? (sum / numericCount) : 0.0;
    return RangeStats(
      count: count,
      numericCount: numericCount,
      sum: sum,
      average: avg,
      min: minVal == double.infinity ? 0 : minVal,
      max: maxVal == double.negativeInfinity ? 0 : maxVal,
    );
  }

  SheetData copy() {
    final newCells = <String, CellData>{};
    cells.forEach((k, v) {
      newCells[k] = v.copy();
    });
    return SheetData(
      name: name,
      cells: newCells,
      rowCount: rowCount,
      colCount: colCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'rowCount': rowCount,
        'colCount': colCount,
        'cells': cells.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory SheetData.fromJson(Map<String, dynamic> json) {
    final cellsMap = <String, CellData>{};
    if (json['cells'] != null) {
      final rawCells = json['cells'] as Map<String, dynamic>;
      rawCells.forEach((k, v) {
        cellsMap[k] = CellData.fromJson(v);
      });
    }
    return SheetData(
      name: json['name'] ?? 'Sheet1',
      rowCount: json['rowCount'] ?? 60,
      colCount: json['colCount'] ?? 26,
      cells: cellsMap,
    );
  }
}

class Workbook {
  String title;
  List<SheetData> sheets;
  int activeSheetIndex;

  Workbook({
    this.title = 'Green_Workbook_2026',
    List<SheetData>? sheets,
    this.activeSheetIndex = 0,
  }) : sheets = sheets ?? [SheetData(name: 'Sheet1')];

  SheetData get activeSheet => sheets[activeSheetIndex];

  void addSheet([String? name]) {
    final sheetNum = sheets.length + 1;
    final sheetName = name ?? 'Sheet$sheetNum';
    sheets.add(SheetData(name: sheetName));
    activeSheetIndex = sheets.length - 1;
  }

  void deleteSheet(int index) {
    if (sheets.length <= 1) return;
    sheets.removeAt(index);
    if (activeSheetIndex >= sheets.length) {
      activeSheetIndex = sheets.length - 1;
    }
  }

  Workbook copy() {
    return Workbook(
      title: title,
      sheets: sheets.map((s) => s.copy()).toList(),
      activeSheetIndex: activeSheetIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'activeSheetIndex': activeSheetIndex,
        'sheets': sheets.map((s) => s.toJson()).toList(),
      };

  factory Workbook.fromJson(Map<String, dynamic> json) {
    final sheetsList = <SheetData>[];
    if (json['sheets'] != null) {
      for (final s in json['sheets']) {
        sheetsList.add(SheetData.fromJson(s));
      }
    }
    return Workbook(
      title: json['title'] ?? 'Green_Workbook_2026',
      sheets: sheetsList.isEmpty ? [SheetData(name: 'Sheet1')] : sheetsList,
      activeSheetIndex: json['activeSheetIndex'] ?? 0,
    );
  }
}
