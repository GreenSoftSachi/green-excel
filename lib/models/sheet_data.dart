import 'cell_data.dart';

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
