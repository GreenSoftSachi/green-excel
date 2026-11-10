import 'package:flutter/material.dart';

class FormulaBar extends StatelessWidget {
  final String activeCellKey;
  final TextEditingController controller;
  final VoidCallback onCommit;
  final VoidCallback onCancel;
  final VoidCallback onFunctionTap;

  const FormulaBar({
    super.key,
    required this.activeCellKey,
    required this.controller,
    required this.onCommit,
    required this.onCancel,
    required this.onFunctionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Active Cell Name Box
          Container(
            width: 58,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF107C41), width: 1.5),
            ),
            child: Text(
              activeCellKey,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF107C41),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // fx button
          InkWell(
            onTap: onFunctionTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF107C41).withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'fx',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                  color: Color(0xFF107C41),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Cancel button
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            tooltip: 'Cancel Edit',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: onCancel,
          ),

          // Commit button
          IconButton(
            icon: const Icon(Icons.check, size: 20, color: Color(0xFF107C41)),
            tooltip: 'Commit (Enter)',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: onCommit,
          ),
          const SizedBox(width: 4),

          // Formula input field
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: 'Enter text, number, or formula (=SUM, =REGEXTEST, =PY...)',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.normal),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onSubmitted: (_) => onCommit(),
            ),
          ),
        ],
      ),
    );
  }
}
