import 'package:flutter/material.dart';

class FormulaBar extends StatefulWidget {
  final String activeRangeText;
  final TextEditingController controller;
  final VoidCallback onCommit;
  final VoidCallback onCancel;
  final VoidCallback onFunctionTap;

  const FormulaBar({
    super.key,
    required this.activeRangeText,
    required this.controller,
    required this.onCommit,
    required this.onCancel,
    required this.onFunctionTap,
  });

  @override
  State<FormulaBar> createState() => _FormulaBarState();
}

class _FormulaBarState extends State<FormulaBar> {
  bool _isExpanded = false;

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
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                // Name Box (A1, Range)
                Container(
                  width: 68,
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.activeRangeText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF107C41),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // fx Formula button
                InkWell(
                  onTap: widget.onFunctionTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF107C41).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'fx',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        color: Color(0xFF107C41),
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),

                // Cancel button
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  tooltip: 'Cancel',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: widget.onCancel,
                ),

                // Commit button
                IconButton(
                  icon: const Icon(Icons.check, size: 18, color: Color(0xFF107C41)),
                  tooltip: 'Enter',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: widget.onCommit,
                ),
                const SizedBox(width: 4),

                // Formula Input Field
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    maxLines: _isExpanded ? 3 : 1,
                    style: const TextStyle(fontSize: 12.5, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText: 'Enter text, value, or formula (=SUM, =XLOOKUP, =PY...)',
                      hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey, fontStyle: FontStyle.normal),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    ),
                    onSubmitted: (_) => widget.onCommit(),
                  ),
                ),

                // Expand / Collapse Formula Bar toggle
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey.shade700,
                  ),
                  tooltip: _isExpanded ? 'Collapse Formula Bar' : 'Expand Formula Bar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
