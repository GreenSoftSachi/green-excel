import 'package:flutter/material.dart';
import '../models/cell_data.dart';

enum RibbonTab {
  home('Home', Icons.home_outlined),
  insert('Insert', Icons.add_circle_outline),
  formulas('Formulas 2026', Icons.functions),
  copilot('Copilot AI', Icons.auto_awesome),
  print('Page & Print', Icons.print_outlined);

  final String title;
  final IconData icon;
  const RibbonTab(this.title, this.icon);
}

class RibbonToolbar extends StatefulWidget {
  final CellStyle activeStyle;
  final bool isCheckbox;
  final Function(CellStyle newStyle) onStyleChanged;
  final VoidCallback onToggleCheckbox;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onOpenCopilot;
  final VoidCallback onOpenCharts;
  final VoidCallback onOpenPrint;
  final Function(String formula) onInsertFormula;
  final VoidCallback onClearCell;
  final VoidCallback onSortAsc;
  final VoidCallback onSortDesc;

  const RibbonToolbar({
    super.key,
    required this.activeStyle,
    required this.isCheckbox,
    required this.onStyleChanged,
    required this.onToggleCheckbox,
    required this.onUndo,
    required this.onRedo,
    required this.onOpenCopilot,
    required this.onOpenCharts,
    required this.onOpenPrint,
    required this.onInsertFormula,
    required this.onClearCell,
    required this.onSortAsc,
    required this.onSortDesc,
  });

  @override
  State<RibbonToolbar> createState() => _RibbonToolbarState();
}

class _RibbonToolbarState extends State<RibbonToolbar> {
  RibbonTab _activeTab = RibbonTab.home;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ribbon Tabs Bar (Excel Fluent Design)
          Container(
            height: 36,
            color: const Color(0xFFF8F9FA),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: RibbonTab.values.map((tab) {
                final isSelected = _activeTab == tab;
                final isCopilot = tab == RibbonTab.copilot;

                return InkWell(
                  onTap: () {
                    if (isCopilot) {
                      widget.onOpenCopilot();
                    } else {
                      setState(() => _activeTab = tab);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? const Color(0xFF107C41) : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      color: isSelected ? Colors.white : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tab.icon,
                          size: 15,
                          color: isCopilot
                              ? const Color(0xFF107C41)
                              : (isSelected ? const Color(0xFF107C41) : Colors.grey.shade700),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          tab.title,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isCopilot
                                ? const Color(0xFF107C41)
                                : (isSelected ? const Color(0xFF107C41) : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Ribbon Actions Bar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildTabActions(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabActions() {
    switch (_activeTab) {
      case RibbonTab.home:
        return _buildHomeTab();
      case RibbonTab.insert:
        return _buildInsertTab();
      case RibbonTab.formulas:
        return _buildFormulasTab();
      case RibbonTab.copilot:
        return _buildCopilotTab();
      case RibbonTab.print:
        return _buildPrintTab();
    }
  }

  Widget _buildHomeTab() {
    return Row(
      children: [
        // Undo / Redo
        _actionButton(Icons.undo, 'Undo', widget.onUndo),
        _actionButton(Icons.redo, 'Redo', widget.onRedo),
        _vDivider(),

        // Font Style: Bold, Italic, Underline
        _toggleButton(
          Icons.format_bold,
          widget.activeStyle.isBold,
          () => widget.onStyleChanged(widget.activeStyle.copyWith(isBold: !widget.activeStyle.isBold)),
        ),
        _toggleButton(
          Icons.format_italic,
          widget.activeStyle.isItalic,
          () => widget.onStyleChanged(widget.activeStyle.copyWith(isItalic: !widget.activeStyle.isItalic)),
        ),
        _toggleButton(
          Icons.format_underlined,
          widget.activeStyle.isUnderline,
          () => widget.onStyleChanged(widget.activeStyle.copyWith(isUnderline: !widget.activeStyle.isUnderline)),
        ),
        _vDivider(),

        // Font Size adjust
        Row(
          children: [
            _actionButton(
              Icons.text_decrease,
              'Decrease Font Size',
              () {
                if (widget.activeStyle.fontSize > 9) {
                  widget.onStyleChanged(widget.activeStyle.copyWith(fontSize: widget.activeStyle.fontSize - 1));
                }
              },
            ),
            Text(
              '${widget.activeStyle.fontSize.toInt()}pt',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            _actionButton(
              Icons.text_increase,
              'Increase Font Size',
              () {
                if (widget.activeStyle.fontSize < 24) {
                  widget.onStyleChanged(widget.activeStyle.copyWith(fontSize: widget.activeStyle.fontSize + 1));
                }
              },
            ),
          ],
        ),
        _vDivider(),

        // Alignments
        _toggleButton(
          Icons.format_align_left,
          widget.activeStyle.alignment == TextAlign.left,
          () => widget.onStyleChanged(widget.activeStyle.copyWith(alignment: TextAlign.left)),
        ),
        _toggleButton(
          Icons.format_align_center,
          widget.activeStyle.alignment == TextAlign.center,
          () => widget.onStyleChanged(widget.activeStyle.copyWith(alignment: TextAlign.center)),
        ),
        _toggleButton(
          Icons.format_align_right,
          widget.activeStyle.alignment == TextAlign.right,
          () => widget.onStyleChanged(widget.activeStyle.copyWith(alignment: TextAlign.right)),
        ),
        _vDivider(),

        // Cell Fill & Text Colors
        _colorPickerButton(
          'Fill',
          Icons.format_color_fill,
          [
            Colors.white,
            const Color(0xFFE8F5E9),
            const Color(0xFFC8E6C9),
            const Color(0xFFFFF9C4),
            const Color(0xFFFFCCBC),
            const Color(0xFFE1F5FE),
            const Color(0xFFF3E5F5),
            const Color(0xFFECEFF1),
          ],
          (c) => widget.onStyleChanged(widget.activeStyle.copyWith(backgroundColor: c)),
        ),
        _colorPickerButton(
          'Text',
          Icons.format_color_text,
          [
            const Color(0xFF212529),
            const Color(0xFF107C41),
            const Color(0xFF1E3A8A),
            const Color(0xFFC62828),
            const Color(0xFFE65100),
            const Color(0xFF4A148C),
          ],
          (c) => widget.onStyleChanged(widget.activeStyle.copyWith(textColor: c)),
        ),
        _vDivider(),

        // Number Format Dropdown
        PopupMenuButton<CellNumberFormat>(
          tooltip: 'Number Format',
          initialValue: widget.activeStyle.numberFormat,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.tag, size: 14, color: Color(0xFF107C41)),
                const SizedBox(width: 4),
                Text(_formatLabel(widget.activeStyle.numberFormat), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                const Icon(Icons.arrow_drop_down, size: 14),
              ],
            ),
          ),
          onSelected: (fmt) => widget.onStyleChanged(widget.activeStyle.copyWith(numberFormat: fmt)),
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: CellNumberFormat.general, child: Text('General')),
            const PopupMenuItem(value: CellNumberFormat.number, child: Text('Number (1,234.00)')),
            const PopupMenuItem(value: CellNumberFormat.currencyUSD, child: Text('Currency USD (\$1,234.00)')),
            const PopupMenuItem(value: CellNumberFormat.currencyLKR, child: Text('Currency LKR (Rs. 1,234.00)')),
            const PopupMenuItem(value: CellNumberFormat.percentage, child: Text('Percentage (%)')),
            const PopupMenuItem(value: CellNumberFormat.date, child: Text('Date (YYYY-MM-DD)')),
          ],
        ),
        const SizedBox(width: 6),

        // Clear Cell
        _actionButton(Icons.backspace_outlined, 'Clear Cell', widget.onClearCell),
      ],
    );
  }

  Widget _buildInsertTab() {
    return Row(
      children: [
        // 2026 Interactive Checkbox Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isCheckbox ? const Color(0xFFE8F5E9) : const Color(0xFF107C41),
            foregroundColor: widget.isCheckbox ? const Color(0xFF107C41) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: Icon(widget.isCheckbox ? Icons.check_box : Icons.check_box_outline_blank, size: 15),
          label: Text(widget.isCheckbox ? 'Remove Checkbox' : 'Insert Checkbox (2026)'),
          onPressed: widget.onToggleCheckbox,
        ),
        const SizedBox(width: 8),

        // Visualizer Charts
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E3A8A),
            side: const BorderSide(color: Color(0xFF1E3A8A)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.bar_chart, size: 15),
          label: const Text('Insert Chart (Bar/Pie/Line)'),
          onPressed: widget.onOpenCharts,
        ),
        _vDivider(),

        _chipButton('Sort A-Z', Icons.arrow_downward, widget.onSortAsc),
        _chipButton('Sort Z-A', Icons.arrow_upward, widget.onSortDesc),
      ],
    );
  }

  Widget _buildFormulasTab() {
    return Row(
      children: [
        _formulaChip('=SUM()', '=SUM('),
        _formulaChip('=AVERAGE()', '=AVERAGE('),
        _formulaChip('=IF()', '=IF('),
        _formulaChip('=XLOOKUP() [2026]', '=XLOOKUP('),
        _vDivider(),
        // 2026 Innovations
        _formulaChip('=REGEXTEST() [2026]', '=REGEXTEST('),
        _formulaChip('=REGEXEXTRACT() [2026]', '=REGEXEXTRACT('),
        _formulaChip('=PY() Python [2026]', '=PY('),
        _formulaChip('=UNIQUE()', '=UNIQUE('),
        _formulaChip('=SORT()', '=SORT('),
      ],
    );
  }

  Widget _buildCopilotTab() {
    return Row(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF107C41),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.auto_awesome, size: 15, color: Color(0xFF86EFAC)),
          label: const Text('Launch Copilot 2026 AI Assistant'),
          onPressed: widget.onOpenCopilot,
        ),
      ],
    );
  }

  Widget _buildPrintTab() {
    return Row(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF107C41),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.print, size: 15),
          label: const Text('Page Setup & Print / PDF'),
          onPressed: widget.onOpenPrint,
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 16, color: Colors.grey.shade800),
      tooltip: tooltip,
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      padding: EdgeInsets.zero,
    );
  }

  Widget _toggleButton(IconData icon, bool isActive, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF107C41).withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isActive ? const Color(0xFF107C41) : Colors.transparent),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: isActive ? const Color(0xFF107C41) : Colors.grey.shade800),
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _colorPickerButton(String label, IconData icon, List<Color> colors, Function(Color) onSelect) {
    return PopupMenuButton<Color>(
      tooltip: '$label Color',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade800),
            const Icon(Icons.arrow_drop_down, size: 12),
          ],
        ),
      ),
      onSelected: onSelect,
      itemBuilder: (ctx) => colors.map((c) {
        return PopupMenuItem(
          value: c,
          child: Row(
            children: [
              Container(width: 18, height: 18, color: c, margin: const EdgeInsets.only(right: 8)),
              Text('#${c.value.toRadixString(16).substring(2).toUpperCase()}'),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _formulaChip(String label, String formulaStart) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        backgroundColor: const Color(0xFFF8F9FA),
        side: BorderSide(color: Colors.grey.shade300),
        onPressed: () => widget.onInsertFormula(formulaStart),
      ),
    );
  }

  Widget _chipButton(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: ActionChip(
        avatar: Icon(icon, size: 13),
        label: Text(label, style: const TextStyle(fontSize: 10.5)),
        backgroundColor: const Color(0xFFF8F9FA),
        onPressed: onTap,
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: Colors.grey.shade300,
    );
  }

  String _formatLabel(CellNumberFormat fmt) {
    switch (fmt) {
      case CellNumberFormat.general: return 'General';
      case CellNumberFormat.number: return 'Number';
      case CellNumberFormat.currencyUSD: return 'USD (\$)';
      case CellNumberFormat.currencyLKR: return 'LKR (Rs.)';
      case CellNumberFormat.percentage: return 'Percentage (%)';
      case CellNumberFormat.date: return 'Date';
    }
  }
}
