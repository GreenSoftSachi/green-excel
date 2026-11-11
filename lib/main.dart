import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/cell_data.dart';
import 'models/sheet_data.dart';
import 'models/user_account.dart';
import 'engine/formula_evaluator.dart';
import 'services/storage_service.dart';
import 'widgets/formula_bar.dart';
import 'widgets/ribbon_toolbar.dart';
import 'widgets/spreadsheet_grid.dart';
import 'widgets/status_bar.dart';
import 'widgets/copilot_sheet.dart';
import 'widgets/chart_view.dart';
import 'widgets/print_dialog.dart';
import 'widgets/auth_dialog.dart';
import 'widgets/about_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const GreenExcelApp());
}

class GreenExcelApp extends StatelessWidget {
  const GreenExcelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Green Excel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF107C41),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF107C41),
          primary: const Color(0xFF107C41),
          secondary: const Color(0xFF185ABD),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF107C41),
          foregroundColor: Colors.white,
          elevation: 1,
        ),
      ),
      home: const ExcelHomeScreen(),
    );
  }
}

class ExcelHomeScreen extends StatefulWidget {
  const ExcelHomeScreen({super.key});

  @override
  State<ExcelHomeScreen> createState() => _ExcelHomeScreenState();
}

class _ExcelHomeScreenState extends State<ExcelHomeScreen> {
  late Workbook _workbook;
  int _activeRow = 0;
  int _activeCol = 0;
  CellRange _selection = const CellRange(startRow: 0, startCol: 0, endRow: 0, endCol: 0);
  RangeStats _rangeStats = const RangeStats();

  UserAccount _userAccount = UserAccount.mockGoogle('Sachinthaka Sandaruwan', 'sachinthaka.sandaruwan@gmail.com');

  final TextEditingController _formulaController = TextEditingController();
  final List<Workbook> _undoStack = [];
  final List<Workbook> _redoStack = [];
  bool _isAutoSaved = true;

  @override
  void initState() {
    super.initState();
    _workbook = StorageService.createBudgetTemplate();
    _syncFormulaBar();
    _updateStats();
  }

  void _pushHistory() {
    _undoStack.add(_workbook.copy());
    if (_undoStack.length > 25) _undoStack.removeAt(0);
    _redoStack.clear();
    _isAutoSaved = false;
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_workbook.copy());
      setState(() {
        _workbook = _undoStack.removeLast();
        _recalculate();
        _syncFormulaBar();
        _updateStats();
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_workbook.copy());
      setState(() {
        _workbook = _redoStack.removeLast();
        _recalculate();
        _syncFormulaBar();
        _updateStats();
      });
    }
  }

  void _recalculate() {
    FormulaEvaluator.evaluateAll(_workbook.activeSheet);
    StorageService.saveWorkbook(_workbook);
    _isAutoSaved = true;
    _updateStats();
  }

  void _updateStats() {
    _rangeStats = _workbook.activeSheet.computeRangeStats(_selection);
  }

  void _syncFormulaBar() {
    final cell = _workbook.activeSheet.getCell(_activeRow, _activeCol);
    _formulaController.text = cell.isFormula
        ? cell.rawValue
        : (cell.isCheckbox ? (cell.checked ? 'TRUE' : 'FALSE') : cell.rawValue);
  }

  void _onSelectCell(int r, int c) {
    setState(() {
      _activeRow = r;
      _activeCol = c;
      _syncFormulaBar();
    });
  }

  void _onSelectRange(int sR, int sC, int eR, int eC) {
    setState(() {
      _selection = CellRange(startRow: sR, startCol: sC, endRow: eR, endCol: eC);
      _updateStats();
    });
  }

  void _onCommitFormula() {
    _pushHistory();
    setState(() {
      final cell = _workbook.activeSheet.getCell(_activeRow, _activeCol);
      cell.rawValue = _formulaController.text.trim();
      _recalculate();
      _syncFormulaBar();
    });
  }

  void _onCancelFormula() {
    setState(() {
      _syncFormulaBar();
    });
  }

  void _onStyleChanged(CellStyle newStyle) {
    _pushHistory();
    setState(() {
      // Apply style to all cells in selected range
      for (int r = _selection.minRow; r <= _selection.maxRow; r++) {
        for (int c = _selection.minCol; c <= _selection.maxCol; c++) {
          final cell = _workbook.activeSheet.getCell(r, c);
          cell.style = newStyle;
        }
      }
      _recalculate();
    });
  }

  void _onToggleCheckbox() {
    _pushHistory();
    setState(() {
      for (int r = _selection.minRow; r <= _selection.maxRow; r++) {
        for (int c = _selection.minCol; c <= _selection.maxCol; c++) {
          final cell = _workbook.activeSheet.getCell(r, c);
          cell.isCheckbox = !cell.isCheckbox;
          if (cell.isCheckbox) {
            cell.checked = false;
            cell.rawValue = 'FALSE';
          }
        }
      }
      _recalculate();
      _syncFormulaBar();
    });
  }

  void _onCheckboxCellToggled(int r, int c, bool checked) {
    _pushHistory();
    setState(() {
      final cell = _workbook.activeSheet.getCell(r, c);
      cell.checked = checked;
      cell.rawValue = checked ? 'TRUE' : 'FALSE';
      _recalculate();
      if (r == _activeRow && c == _activeCol) _syncFormulaBar();
    });
  }

  void _onClearCell() {
    _pushHistory();
    setState(() {
      for (int r = _selection.minRow; r <= _selection.maxRow; r++) {
        for (int c = _selection.minCol; c <= _selection.maxCol; c++) {
          final cell = _workbook.activeSheet.getCell(r, c);
          cell.rawValue = '';
          cell.computedValue = '';
          cell.isCheckbox = false;
          cell.checked = false;
        }
      }
      _recalculate();
      _syncFormulaBar();
    });
  }

  void _onSort(bool ascending) {
    _pushHistory();
    setState(() {
      final sheet = _workbook.activeSheet;
      final rowsData = <List<CellData>>[];
      for (int r = 1; r < sheet.rowCount; r++) {
        final row = <CellData>[];
        bool hasData = false;
        for (int c = 0; c < sheet.colCount; c++) {
          final cd = sheet.getCell(r, c).copy();
          if (cd.computedValue.isNotEmpty || cd.isCheckbox) hasData = true;
          row.add(cd);
        }
        if (hasData) rowsData.add(row);
      }

      rowsData.sort((a, b) {
        final valA = a[_activeCol].computedValue;
        final valB = b[_activeCol].computedValue;
        final numA = double.tryParse(valA.replaceAll('\$', '').replaceAll('Rs.', '').replaceAll(',', '').trim());
        final numB = double.tryParse(valB.replaceAll('\$', '').replaceAll('Rs.', '').replaceAll(',', '').trim());
        if (numA != null && numB != null) {
          return ascending ? numA.compareTo(numB) : numB.compareTo(numA);
        }
        return ascending ? valA.compareTo(valB) : valB.compareTo(valA);
      });

      for (int i = 0; i < rowsData.length; i++) {
        final r = i + 1;
        for (int c = 0; c < sheet.colCount; c++) {
          sheet.setCell(r, c, rowsData[i][c]);
        }
      }
      _recalculate();
    });
  }

  void _showFunctionHelper() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.functions, color: Color(0xFF107C41), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Insert Function (fx) - 2026 Engine',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _fxChip(ctx, '=SUM(', 'Math Sum'),
                _fxChip(ctx, '=AVERAGE(', 'Mean Average'),
                _fxChip(ctx, '=IF(', 'Condition IF'),
                _fxChip(ctx, '=XLOOKUP(', 'Modern XLOOKUP'),
                _fxChip(ctx, '=REGEXTEST(', '2026 Regex Test'),
                _fxChip(ctx, '=REGEXEXTRACT(', '2026 Regex Extract'),
                _fxChip(ctx, '=REGEXREPLACE(', '2026 Regex Replace'),
                _fxChip(ctx, '=PY(', '2026 Python in Excel'),
                _fxChip(ctx, '=UNIQUE(', 'Dynamic Unique'),
                _fxChip(ctx, '=SORT(', 'Dynamic Sort'),
                _fxChip(ctx, '=COUNT(', 'Count'),
                _fxChip(ctx, '=MAX(', 'Maximum'),
                _fxChip(ctx, '=MIN(', 'Minimum'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fxChip(BuildContext ctx, String code, String label) {
    return ActionChip(
      avatar: const Icon(Icons.add, size: 14, color: Color(0xFF107C41)),
      label: Text('$label ($code)'),
      onPressed: () {
        Navigator.pop(ctx);
        _insertFormulaSnippet(code);
      },
    );
  }

  void _insertFormulaSnippet(String code) {
    _formulaController.text = code;
    _formulaController.selection = TextSelection.fromPosition(
      TextPosition(offset: _formulaController.text.length),
    );
  }

  void _openCopilot() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => CopilotSheet(
        sheet: _workbook.activeSheet,
        activeCellKey: _selection.toRangeString(),
        onApplyFormula: (formula) {
          _pushHistory();
          setState(() {
            final cell = _workbook.activeSheet.getCell(_activeRow, _activeCol);
            cell.rawValue = formula;
            _recalculate();
            _syncFormulaBar();
          });
        },
        onThemeApplied: () {
          setState(() {
            _recalculate();
          });
        },
      ),
    );
  }

  void _openCharts() {
    showDialog(
      context: context,
      builder: (ctx) => ChartViewDialog(sheet: _workbook.activeSheet),
    );
  }

  void _openPrintDialog() {
    showDialog(
      context: context,
      builder: (ctx) => PrintDialog(sheet: _workbook.activeSheet),
    );
  }

  void _openAuthDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AuthDialog(
        currentUser: _userAccount,
        onAccountChanged: (newAcc) {
          setState(() => _userAccount = newAcc);
        },
      ),
    );
  }

  void _openAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const AboutAppDialog(),
    );
  }

  void _onCellDoubleTapped() {
    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController(text: _formulaController.text);
        return AlertDialog(
          title: Text('Edit Cell ${SheetData.cellKey(_activeRow, _activeCol)}'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Cell Value or Formula',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF107C41), foregroundColor: Colors.white),
              onPressed: () {
                _formulaController.text = ctrl.text;
                _onCommitFormula();
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCell = _workbook.activeSheet.getCell(_activeRow, _activeCol);
    final rangeStr = _selection.toRangeString();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          children: [
            // App Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            // App Name & Save Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Green Excel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _isAutoSaved ? const Color(0xFF86EFAC) : Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isAutoSaved ? 'AutoSaved • GridCraft Pro' : 'Editing...',
                        style: const TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Copilot AI Sparkle Action
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.18),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.auto_awesome, size: 15, color: Color(0xFF86EFAC)),
            label: const Text('Copilot 2026', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            onPressed: _openCopilot,
          ),
          const SizedBox(width: 2),

          // Print & PDF
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Options & PDF',
            onPressed: _openPrintDialog,
          ),

          // Charts
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Visualizer & Charts',
            onPressed: _openCharts,
          ),

          // Cloud User Avatar
          InkWell(
            onTap: _openAuthDialog,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: _userAccount.provider == AuthProviderType.microsoft
                    ? const Color(0xFF0078D4)
                    : (_userAccount.provider == AuthProviderType.google ? const Color(0xFFEA4335) : Colors.grey.shade700),
                child: Text(
                  _userAccount.displayName.isNotEmpty ? _userAccount.displayName[0].toUpperCase() : 'G',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // Overflow Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              switch (val) {
                case 'about':
                  _openAboutDialog();
                  break;
                case 'new_blank':
                  _pushHistory();
                  setState(() {
                    _workbook = Workbook(sheets: [SheetData(name: 'Sheet1')]);
                    _recalculate();
                    _syncFormulaBar();
                  });
                  break;
                case 'template_budget':
                  _pushHistory();
                  setState(() {
                    _workbook = StorageService.createBudgetTemplate();
                    _recalculate();
                    _syncFormulaBar();
                  });
                  break;
                case 'template_sales':
                  _pushHistory();
                  setState(() {
                    _workbook = StorageService.createSalesTemplate();
                    _recalculate();
                    _syncFormulaBar();
                  });
                  break;
                case 'share_csv':
                  StorageService.shareCsv(_workbook.activeSheet);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF107C41)),
                    SizedBox(width: 10),
                    Text('About Developer (Sachinthaka)'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'template_budget',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined),
                    SizedBox(width: 10),
                    Text('Load Budget 2026 Template'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'template_sales',
                child: Row(
                  children: [
                    Icon(Icons.trending_up),
                    SizedBox(width: 10),
                    Text('Load Sales Dashboard Template'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'new_blank',
                child: Row(
                  children: [
                    Icon(Icons.note_add_outlined),
                    SizedBox(width: 10),
                    Text('New Blank Workbook'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'share_csv',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined),
                    SizedBox(width: 10),
                    Text('Export & Share CSV'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Ribbon Toolbar (Home, Insert, Formulas, Copilot, Print)
            RibbonToolbar(
              activeStyle: activeCell.style,
              isCheckbox: activeCell.isCheckbox,
              onStyleChanged: _onStyleChanged,
              onToggleCheckbox: _onToggleCheckbox,
              onUndo: _undo,
              onRedo: _redo,
              onOpenCopilot: _openCopilot,
              onOpenCharts: _openCharts,
              onOpenPrint: _openPrintDialog,
              onInsertFormula: (code) => _insertFormulaSnippet(code),
              onClearCell: _onClearCell,
              onSortAsc: () => _onSort(true),
              onSortDesc: () => _onSort(false),
            ),

            // Top Formula Bar with Name Box & Multi-line Expand
            FormulaBar(
              activeRangeText: rangeStr,
              controller: _formulaController,
              onCommit: _onCommitFormula,
              onCancel: _onCancelFormula,
              onFunctionTap: _showFunctionHelper,
            ),

            // Main Spreadsheet Grid Matrix
            Expanded(
              child: SpreadsheetGrid(
                sheet: _workbook.activeSheet,
                selection: _selection,
                activeRow: _activeRow,
                activeCol: _activeCol,
                onSelectCell: _onSelectCell,
                onSelectRange: _onSelectRange,
                onCheckboxToggled: _onCheckboxCellToggled,
                onCellDoubleTapped: _onCellDoubleTapped,
              ),
            ),

            // Sheet Tabs Bar (Sheet1, Sheet2, +)
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _workbook.sheets.length,
                      itemBuilder: (ctx, idx) {
                        final sheet = _workbook.sheets[idx];
                        final isActive = idx == _workbook.activeSheetIndex;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _workbook.activeSheetIndex = idx;
                              _selection = const CellRange(startRow: 0, startCol: 0, endRow: 0, endCol: 0);
                              _activeRow = 0;
                              _activeCol = 0;
                              _recalculate();
                              _syncFormulaBar();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white : Colors.transparent,
                              border: Border(
                                top: BorderSide(
                                  color: isActive ? const Color(0xFF107C41) : Colors.transparent,
                                  width: 2.5,
                                ),
                                right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  sheet.name,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                    color: isActive ? const Color(0xFF107C41) : Colors.grey.shade800,
                                  ),
                                ),
                                if (_workbook.sheets.length > 1 && isActive) ...[
                                  const SizedBox(width: 5),
                                  GestureDetector(
                                    onTap: () {
                                      _pushHistory();
                                      setState(() {
                                        _workbook.deleteSheet(idx);
                                        _recalculate();
                                        _syncFormulaBar();
                                      });
                                    },
                                    child: const Icon(Icons.close, size: 12, color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Add Sheet Button
                  IconButton(
                    icon: const Icon(Icons.add, size: 18, color: Color(0xFF107C41)),
                    tooltip: 'Add Sheet',
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: () {
                      _pushHistory();
                      setState(() {
                        _workbook.addSheet();
                        _selection = const CellRange(startRow: 0, startCol: 0, endRow: 0, endCol: 0);
                        _activeRow = 0;
                        _activeCol = 0;
                        _recalculate();
                        _syncFormulaBar();
                      });
                    },
                  ),
                ],
              ),
            ),

            // Iconic Live Status Bar at Bottom (SUM, AVERAGE, COUNT, Ready)
            ExcelStatusBar(
              stats: _rangeStats,
              isAutoSaved: _isAutoSaved,
              activeRangeText: rangeStr,
            ),
          ],
        ),
      ),
    );
  }
}
