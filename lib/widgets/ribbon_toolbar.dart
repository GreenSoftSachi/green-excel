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
          // Ribbon Tab Bar
          Container(
            height: 38,
            color: const Color(0xFFF3F4F6),
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
                          size: 16,
                          color: isCopilot
                              ? const Color(0xFF107C41)
                              : (isSelected ? const Color(0xFF107C41) : Colors.grey.shade700),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tab.title,
                          style: TextStyle(
                            fontSize: 12,
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

          // Ribbon Actions Content
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

        // Bold
        _toggleButton(
          Icons.format_bold,
          widget.activeStyle.isBold,
          () => widget.onStyleChanged(widget.activeStyle.copyWith(isBold: !widget.activeStyle.isBold)),
        ),
        // Italic
        _toggleButton(
          Icons.format_italic,
          widget.activeStyle.isItalic,
          () => widget.onStyleChanged(widget.activeStyle.copyWith(isItalic: !widget.activeStyle.isItalic)),
        ),
        // Underline
        _toggleButton(
          Icons.format_underlined,
          widget.activeStyle.isUnderline,
          () => widget.onStyleChanged(widget.activeStyle.copyWith(isUnderline: !widget.activeStyle.isUnderline)),
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

        // Fill Colors
        _colorPickerButton(
          'Fill',
          Icons.format_color_fill,
          [Colors.white, const Color(0xFFF3FBF6), const Color(0xFFE1F5EA), const Color(0xFFFEF3C7), const Color(0xFFFEE2E2), const Color(0xFFEFF6FF), const Color(0xFFF3E8FF)],
          (c) => widget.onStyleChanged(widget.activeStyle.copyWith(backgroundColor: c)),
        ),
        // Text Colors
        _colorPickerButton(
          'Text',
          Icons.format_color_text,
          [const Color(0xFF212529), const Color(0xFF107C41), const Color(0xFF1E3A8A), const Color(0xFFDC2626), const Color(0xFFD97706), const Color(0xFF7C3AED)],
          (c) => widget.onStyleChanged(widget.activeStyle.copyWith(textColor: c)),
        ),
        _vDivider(),

        // Number Format Dropdown
        PopupMenuButton<CellNumberFormat>(
          tooltip: 'Number Format',
          initialValue: widget.activeStyle.numberFormat,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.pin, size: 16, color: Color(0xFF107C41)),
                const SizedBox(width: 4),
                Text(_formatLabel(widget.activeStyle.numberFormat), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const Icon(Icons.arrow_drop_down, size: 16),
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
        const SizedBox(width: 8),

        // Clear Cell
        _actionButton(Icons.backspace_outlined, 'Clear Cell', widget.onClearCell),
      ],
    );
  }

  Widget _buildInsertTab() {
    return Row(
      children: [
        // 2026 Checkbox Feature
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isCheckbox ? Colors.green.shade100 : const Color(0xFF107C41),
            foregroundColor: widget.isCheckbox ? const Color(0xFF107C41) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          icon: Icon(widget.isCheckbox ? Icons.check_box : Icons.check_box_outline_blank, size: 16),
          label: Text(widget.isCheckbox ? 'Remove Checkbox' : 'Insert Checkbox (2026)'),
          onPressed: widget.onToggleCheckbox,
        ),
        const SizedBox(width: 8),

        // Charts
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E3A8A),
            side: const BorderSide(color: Color(0xFF1E3A8A)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.bar_chart, size: 16),
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
        _formulaChip('=XLOOKUP()', '=XLOOKUP('),
        _vDivider(),
        // 2026 Highlights
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: const Text('Open Copilot 2026 AI Assistant'),
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
          ),
          icon: const Icon(Icons.print, size: 16),
          label: const Text('Print Setup & Preview'),
          onPressed: widget.onOpenPrint,
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 18, color: Colors.grey.shade800),
      tooltip: tooltip,
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      padding: EdgeInsets.zero,
    );
  }

  Widget _toggleButton(IconData icon, bool isActive, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF107C41).withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isActive ? const Color(0xFF107C41) : Colors.transparent),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: isActive ? const Color(0xFF107C41) : Colors.grey.shade800),
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _colorPickerButton(String label, IconData icon, List<Color> colors, Function(Color) onSelect) {
    return PopupMenuButton<Color>(
      tooltip: '$label Color',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade800),
            const Icon(Icons.arrow_drop_down, size: 14),
          ],
        ),
      ),
      onSelected: onSelect,
      itemBuilder: (ctx) => colors.map((c) {
        return PopupMenuItem(
          value: c,
          child: Row(
            children: [
              Container(width: 20, height: 20, color: c, margin: const EdgeInsets.only(right: 8)),
              Text('#${c.value.toRadixString(16).substring(2).toUpperCase()}'),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _formulaChip(String label, String formulaStart) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        backgroundColor: Colors.grey.shade100,
        side: BorderSide(color: Colors.grey.shade300),
        onPressed: () => widget.onInsertFormula(formulaStart),
      ),
    );
  }

  Widget _chipButton(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        avatar: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        backgroundColor: Colors.grey.shade100,
        onPressed: onTap,
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
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
