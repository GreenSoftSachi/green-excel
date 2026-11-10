import 'package:flutter/material.dart';
import '../models/cell_data.dart';
import '../models/sheet_data.dart';
import '../engine/formula_evaluator.dart';

class SpreadsheetGrid extends StatefulWidget {
  final SheetData sheet;
  final int activeRow;
  final int activeCol;
  final Function(int row, int col) onSelectCell;
  final Function(int row, int col, bool checked) onCheckboxToggled;
  final VoidCallback onCellDoubleTapped;

  const SpreadsheetGrid({
    super.key,
    required this.sheet,
    required this.activeRow,
    required this.activeCol,
    required this.onSelectCell,
    required this.onCheckboxToggled,
    required this.onCellDoubleTapped,
  });

  @override
  State<SpreadsheetGrid> createState() => _SpreadsheetGridState();
}

class _SpreadsheetGridState extends State<SpreadsheetGrid> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final ScrollController _rowHeaderVerticalController = ScrollController();
  final ScrollController _colHeaderHorizontalController = ScrollController();

  static const double colWidth = 92.0;
  static const double rowHeight = 32.0;
  static const double rowHeaderWidth = 44.0;
  static const double colHeaderHeight = 28.0;

  @override
  void initState() {
    super.initState();
    _verticalController.addListener(() {
      if (_rowHeaderVerticalController.hasClients &&
          _rowHeaderVerticalController.offset != _verticalController.offset) {
        _rowHeaderVerticalController.jumpTo(_verticalController.offset);
      }
    });

    _horizontalController.addListener(() {
      if (_colHeaderHorizontalController.hasClients &&
          _colHeaderHorizontalController.offset != _horizontalController.offset) {
        _colHeaderHorizontalController.jumpTo(_horizontalController.offset);
      }
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _rowHeaderVerticalController.dispose();
    _colHeaderHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Top Row: Corner + Column Headers
          Row(
            children: [
              // Corner Cell
              Container(
                width: rowHeaderWidth,
                height: colHeaderHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                ),
                child: const Icon(Icons.grid_on, size: 14, color: Colors.grey),
              ),

              // Column Headers (A, B, C...)
              Expanded(
                child: SizedBox(
                  height: colHeaderHeight,
                  child: ListView.builder(
                    controller: _colHeaderHorizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    itemCount: widget.sheet.colCount,
                    itemBuilder: (context, colIdx) {
                      final isSelectedCol = colIdx == widget.activeCol;
                      final colName = SheetData.indexToColName(colIdx);
                      return Container(
                        width: colWidth,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelectedCol
                              ? const Color(0xFF107C41).withOpacity(0.18)
                              : const Color(0xFFF3F4F6),
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                            bottom: BorderSide(
                              color: isSelectedCol ? const Color(0xFF107C41) : Colors.grey.shade300,
                              width: isSelectedCol ? 2.0 : 0.5,
                            ),
                            top: BorderSide(color: Colors.grey.shade300, width: 0.5),
                          ),
                        ),
                        child: Text(
                          colName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelectedCol ? FontWeight.bold : FontWeight.w600,
                            color: isSelectedCol ? const Color(0xFF107C41) : Colors.grey.shade800,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // Body: Row Headers (1, 2, 3...) + Grid Cells
          Expanded(
            child: Row(
              children: [
                // Row Headers
                SizedBox(
                  width: rowHeaderWidth,
                  child: ListView.builder(
                    controller: _rowHeaderVerticalController,
                    scrollDirection: Axis.vertical,
                    physics: const ClampingScrollPhysics(),
                    itemCount: widget.sheet.rowCount,
                    itemBuilder: (context, rowIdx) {
                      final isSelectedRow = rowIdx == widget.activeRow;
                      return Container(
                        height: rowHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelectedRow
                              ? const Color(0xFF107C41).withOpacity(0.18)
                              : const Color(0xFFF3F4F6),
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                            right: BorderSide(
                              color: isSelectedRow ? const Color(0xFF107C41) : Colors.grey.shade300,
                              width: isSelectedRow ? 2.0 : 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          '${rowIdx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelectedRow ? FontWeight.bold : FontWeight.w600,
                            color: isSelectedRow ? const Color(0xFF107C41) : Colors.grey.shade800,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Data Cells Area
                Expanded(
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(widget.sheet.rowCount, (r) {
                          return Row(
                            children: List.generate(widget.sheet.colCount, (c) {
                              final isSelected = (r == widget.activeRow && c == widget.activeCol);
                              final cell = widget.sheet.getCell(r, c);
                              return SizedBox(
                                width: colWidth,
                                height: rowHeight,
                                child: GestureDetector(
                                  onTap: () => widget.onSelectCell(r, c),
                                  onDoubleTap: widget.onCellDoubleTapped,
                                  child: _buildCellWidget(cell, isSelected, r, c),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellWidget(CellData cell, bool isSelected, int r, int c) {
    final style = cell.style;
    final display = FormulaEvaluator.formatDisplay(cell);

    Border border;
    if (isSelected) {
      border = Border.all(color: const Color(0xFF107C41), width: 2.0);
    } else {
      border = Border.all(color: Colors.grey.shade300, width: 0.5);
    }

    return Container(
      decoration: BoxDecoration(
        color: cell.style.backgroundColor,
        border: border,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.centerLeft,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (cell.isCheckbox)
            Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: cell.checked,
                  activeColor: const Color(0xFF107C41),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) {
                    widget.onCheckboxToggled(r, c, val ?? false);
                  },
                ),
              ),
            )
          else
            Align(
              alignment: _getAlignment(style.alignment),
              child: Text(
                display,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: style.fontSize,
                  fontWeight: style.isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: style.isItalic ? FontStyle.italic : FontStyle.normal,
                  decoration: style.isUnderline ? TextDecoration.underline : TextDecoration.none,
                  color: style.textColor,
                ),
              ),
            ),

          // Classic Excel Selection Handle on bottom right
          if (isSelected)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF107C41),
                  shape: BoxShape.rectangle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Alignment _getAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center: return Alignment.center;
      case TextAlign.right: return Alignment.centerRight;
      case TextAlign.left:
      default: return Alignment.centerLeft;
    }
  }
}
