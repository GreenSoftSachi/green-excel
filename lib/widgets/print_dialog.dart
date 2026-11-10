import 'package:flutter/material.dart';
import '../models/sheet_data.dart';
import '../services/print_service.dart';
import '../services/storage_service.dart';

class PrintDialog extends StatefulWidget {
  final SheetData sheet;

  const PrintDialog({super.key, required this.sheet});

  @override
  State<PrintDialog> createState() => _PrintDialogState();
}

class _PrintDialogState extends State<PrintDialog> {
  PageOrientationType _orientation = PageOrientationType.portrait;
  PaperSizeType _paperSize = PaperSizeType.a4;
  bool _showGridlines = true;
  bool _printHeaderRow = true;
  final TextEditingController _titleController = TextEditingController(text: 'Green Excel Report');
  bool _isProcessing = false;

  void _executePrint() async {
    setState(() => _isProcessing = true);
    try {
      final settings = PrintSettings(
        orientation: _orientation,
        paperSize: _paperSize,
        showGridlines: _showGridlines,
        printHeaderRow: _printHeaderRow,
        title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Green Excel Report',
      );
      await PrintService.printDocument(widget.sheet, settings);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _executeSharePdf() async {
    setState(() => _isProcessing = true);
    try {
      final settings = PrintSettings(
        orientation: _orientation,
        paperSize: _paperSize,
        showGridlines: _showGridlines,
        printHeaderRow: _printHeaderRow,
        title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Green Excel Report',
      );
      await PrintService.sharePdf(widget.sheet, settings);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share PDF Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _executeExportCsv() async {
    try {
      await StorageService.shareCsv(widget.sheet);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV Export Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  const Icon(Icons.print_rounded, color: Color(0xFF107C41), size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Page Setup & Print Options',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Title Field
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Report Header Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title, color: Color(0xFF107C41)),
                ),
              ),
              const SizedBox(height: 16),

              // Orientation
              const Text('Page Orientation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              SegmentedButton<PageOrientationType>(
                segments: const [
                  ButtonSegment(
                    value: PageOrientationType.portrait,
                    label: Text('Portrait (A4)'),
                    icon: Icon(Icons.portrait),
                  ),
                  ButtonSegment(
                    value: PageOrientationType.landscape,
                    label: Text('Landscape'),
                    icon: Icon(Icons.landscape),
                  ),
                ],
                selected: {_orientation},
                onSelectionChanged: (set) {
                  setState(() => _orientation = set.first);
                },
              ),
              const SizedBox(height: 16),

              // Paper Size
              const Text('Paper Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<PaperSizeType>(
                value: _paperSize,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: PaperSizeType.a4, child: Text('A4 Standard (210 x 297 mm)')),
                  DropdownMenuItem(value: PaperSizeType.letter, child: Text('US Letter (8.5 x 11 in)')),
                  DropdownMenuItem(value: PaperSizeType.legal, child: Text('US Legal (8.5 x 14 in)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _paperSize = val);
                },
              ),
              const SizedBox(height: 12),

              // Toggles
              SwitchListTile(
                title: const Text('Print Gridlines', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Show cell borders in printed document', style: TextStyle(fontSize: 12)),
                value: _showGridlines,
                activeColor: const Color(0xFF107C41),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _showGridlines = val),
              ),
              SwitchListTile(
                title: const Text('Include Column Letters (A, B, C...)', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Show header coordinates', style: TextStyle(fontSize: 12)),
                value: _printHeaderRow,
                activeColor: const Color(0xFF107C41),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _printHeaderRow = val),
              ),
              const Divider(height: 24),

              // Action Buttons
              if (_isProcessing)
                const Center(child: CircularProgressIndicator(color: Color(0xFF107C41)))
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF107C41),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.print),
                        label: const Text('Direct Print / Save PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _executePrint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF107C41),
                              side: const BorderSide(color: Color(0xFF107C41)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Share PDF'),
                            onPressed: _executeSharePdf,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E3A8A),
                              side: const BorderSide(color: Color(0xFF1E3A8A)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.table_chart),
                            label: const Text('Share CSV'),
                            onPressed: _executeExportCsv,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
