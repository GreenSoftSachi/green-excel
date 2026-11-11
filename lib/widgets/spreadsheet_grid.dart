import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/cell_data.dart';
import '../models/sheet_data.dart';
import '../engine/formula_evaluator.dart';

class SpreadsheetGrid extends StatefulWidget {
  final SheetData sheet;
  final CellRange selection;
  final int activeRow;
  final int activeCol;
  final Function(int row, int col) onSelectCell;
  final Function(int startRow, int startCol, int endRow, int endCol) onSelectRange;
  final Function(int row, int col, bool checked) onCheckboxToggled;
  final VoidCallback onCellDoubleTapped;

  const SpreadsheetGrid({
    super.key,
    required this.sheet,
    required this.selection,
    required this.activeRow,
    required this.activeCol,
    required this.onSelectCell,
    required this.onSelectRange,
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

  bool _isDragging = false;
  int _dragStartRow = 0;
  int _dragStartCol = 0;

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

  void _handleCellTap(int r, int c) {
    widget.onSelectCell(r, c);
    widget.onSelectRange(r, c, r, c);
  }

  void _handlePanStart(int r, int c) {
    _isDragging = true;
    _dragStartRow = r;
    _dragStartCol = c;
    widget.onSelectCell(r, c);
    widget.onSelectRange(r, c, r, c);
  }

  void _handlePanUpdate(DragUpdateDetails details, int r, int c) {
    if (!_isDragging) return;
    // Calculate targeted cell from drag delta
    final deltaCol = (details.localPosition.dx / colWidth).floor();
    final deltaRow = (details.localPosition.dy / rowHeight).floor();
    final targetRow = (_dragStartRow + deltaRow).clamp(0, widget.sheet.rowCount - 1);
    final targetCol = (_dragStartCol + deltaCol).clamp(0, widget.sheet.colCount - 1);

    widget.onSelectRange(_dragStartRow, _dragStartCol, targetRow, targetCol);
  }

  void _handlePanEnd() {
    _isDragging = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Top Row: Corner + Column Headers (A, B, C...)
          Row(
            children: [
              // Corner Cell
              Container(
                width: rowHeaderWidth,
                height: colHeaderHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade300, width: 1),
                    bottom: BorderSide(color: Colors.grey.shade400, width: 1),
                  ),
                ),
                child: const Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey),
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
                      final isSelectedCol = widget.selection.minCol <= colIdx && colIdx <= widget.selection.maxCol;
                      final isActiveCol = colIdx == widget.activeCol;
                      final colName = SheetData.indexToColName(colIdx);

                      return Container(
                        width: colWidth,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActiveCol
                              ? const Color(0xFFE8F5E9)
                              : (isSelectedCol ? const Color(0xFFE8F5E9).withOpacity(0.5) : const Color(0xFFF8F9FA)),
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade300, width: 1),
                            bottom: BorderSide(
                              color: isSelectedCol ? const Color(0xFF107C41) : Colors.grey.shade400,
                              width: isSelectedCol ? 2.5 : 1,
                            ),
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
                      final isSelectedRow = widget.selection.minRow <= rowIdx && rowIdx <= widget.selection.maxRow;
                      final isActiveRow = rowIdx == widget.activeRow;

                      return Container(
                        height: rowHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActiveRow
                              ? const Color(0xFFE8F5E9)
                              : (isSelectedRow ? const Color(0xFFE8F5E9).withOpacity(0.5) : const Color(0xFFF8F9FA)),
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                            right: BorderSide(
                              color: isSelectedRow ? const Color(0xFF107C41) : Colors.grey.shade400,
                              width: isSelectedRow ? 2.5 : 1,
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

                // Grid Matrix Area
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
                              final isActiveCell = (r == widget.activeRow && c == widget.activeCol);
                              final isInRange = widget.selection.contains(r, c);
                              final cell = widget.sheet.getCell(r, c);

                              return SizedBox(
                                width: colWidth,
                                height: rowHeight,
                                child: GestureDetector(
                                  onTap: () => _handleCellTap(r, c),
                                  onDoubleTap: widget.onCellDoubleTapped,
                                  onPanStart: (_) => _handlePanStart(r, c),
                                  onPanUpdate: (d) => _handlePanUpdate(d, r, c),
                                  onPanEnd: (_) => _handlePanEnd(),
                                  child: _buildCellWidget(cell, isActiveCell, isInRange, r, c),
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

  Widget _buildCellWidget(CellData cell, bool isActive, bool isInRange, int r, int c) {
    final style = cell.style;
    final display = FormulaEvaluator.formatDisplay(cell);

    // Gridcraft Excel Borders & Selection Styling
    Color bgColor = cell.style.backgroundColor;
    if (isInRange && !isActive) {
      bgColor = const Color(0xFFE8F5E9).withOpacity(0.45);
    }

    BoxBorder border;
    if (isActive) {
      border = Border.all(color: const Color(0xFF107C41), width: 2.0);
    } else if (isInRange) {
      final isTop = (r == widget.selection.minRow);
      final isBottom = (r == widget.selection.maxRow);
      final isLeft = (c == widget.selection.minCol);
      final isRight = (c == widget.selection.maxCol);

      border = Border(
        top: isTop ? const BorderSide(color: Color(0xFF107C41), width: 1.5) : BorderSide(color: Colors.grey.shade300, width: 0.5),
        bottom: isBottom ? const BorderSide(color: Color(0xFF107C41), width: 1.5) : BorderSide(color: Colors.grey.shade300, width: 0.5),
        left: isLeft ? const BorderSide(color: Color(0xFF107C41), width: 1.5) : BorderSide(color: Colors.grey.shade300, width: 0.5),
        right: isRight ? const BorderSide(color: Color(0xFF107C41), width: 1.5) : BorderSide(color: Colors.grey.shade300, width: 0.5),
      );
    } else {
      border = Border.all(color: Colors.grey.shade300, width: 0.5);
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: border,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Content
          if (cell.isCheckbox)
            Center(
              child: SizedBox(
                width: 20,
                height: 20,
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

          // Iconic Excel Fill Handle on bottom-right corner of active/range boundary
          if (isActive || (isInRange && r == widget.selection.maxRow && c == widget.selection.maxCol))
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 6.5,
                height: 6.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF107C41),
                  border: Border.all(color: Colors.white, width: 1),
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
