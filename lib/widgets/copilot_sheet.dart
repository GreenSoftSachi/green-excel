import 'package:flutter/material.dart';
import '../models/sheet_data.dart';
import '../engine/copilot_ai.dart';
import '../engine/formula_evaluator.dart';

class CopilotSheet extends StatefulWidget {
  final SheetData sheet;
  final String activeCellKey;
  final Function(String formula) onApplyFormula;
  final VoidCallback onThemeApplied;

  const CopilotSheet({
    super.key,
    required this.sheet,
    required this.activeCellKey,
    required this.onApplyFormula,
    required this.onThemeApplied,
  });

  @override
  State<CopilotSheet> createState() => _CopilotSheetState();
}

class _CopilotSheetState extends State<CopilotSheet> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  CopilotResult? _currentResult;

  final List<String> _quickPrompts = [
    'Sum active column',
    'Calculate average',
    'Validate email with 2026 regex',
    'Find top sales with XLOOKUP',
    'Python list calculation',
  ];

  @override
  void initState() {
    super.initState();
    _currentResult = CopilotAI.generateWorkbookInsights(widget.sheet);
  }

  void _sendQuery(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
    });

    final res = await CopilotAI.processQuery(query, widget.sheet, widget.activeCellKey);
    setState(() {
      _currentResult = res;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF107C41).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF107C41), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Copilot in Excel (July 2026)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Active Cell: ${widget.activeCellKey} | Microsoft 365 AI Engine',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // AI Model Selector (July 2026 Feature: GPT-5.6, Claude Opus 5, Gemini)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, size: 18, color: Color(0xFF107C41)),
                  const SizedBox(width: 8),
                  const Text('AI Model: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<CopilotModel>(
                        value: CopilotAI.activeModel,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF107C41)),
                        items: CopilotModel.values.map((model) {
                          return DropdownMenuItem<CopilotModel>(
                            value: model,
                            child: Text(
                              model.title,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => CopilotAI.activeModel = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quick Prompt Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickPrompts.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(p, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey.shade100,
                      onPressed: () {
                        _promptController.text = p;
                        _sendQuery(p);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Input Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: InputDecoration(
                      hintText: 'Ask Copilot (e.g. "Calculate 15% VAT", "Sum A1:A10")...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF107C41), width: 1.5),
                      ),
                    ),
                    onSubmitted: _sendQuery,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_upward),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF107C41)),
                  onPressed: () => _sendQuery(_promptController.text),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // AI Output Box
            if (_currentResult != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentResult!.message,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF14532D)),
                    ),
                    if (_currentResult!.suggestedFormula != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.functions, size: 18, color: Color(0xFF107C41)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentResult!.suggestedFormula!,
                                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF107C41),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                widget.onApplyFormula(_currentResult!.suggestedFormula!);
                                Navigator.pop(context);
                              },
                              child: const Text('Insert Cell'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_currentResult!.explanation != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _currentResult!.explanation!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                      ),
                    ],
                    if (_currentResult!.insights.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ..._currentResult!.insights.map((ins) => Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Color(0xFF107C41), fontWeight: FontWeight.bold)),
                                Expanded(child: Text(ins, style: const TextStyle(fontSize: 11, color: Color(0xFF14532D)))),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // 2026 Brand Themes
            const Text(
              'Corporate Brand Kits & Themes (July 2026)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CopilotTheme.availableThemes.map((theme) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.primaryHeader, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        CopilotAI.applyBrandTheme(widget.sheet, theme);
                        FormulaEvaluator.evaluateAll(widget.sheet);
                        widget.onThemeApplied();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Applied "${theme.name}" Theme!')),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(color: theme.primaryHeader, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(theme.name, style: TextStyle(color: theme.primaryHeader, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
