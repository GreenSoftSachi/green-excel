import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/cell_data.dart';
import '../models/sheet_data.dart';
import '../engine/formula_evaluator.dart';

enum PageOrientationType {
  portrait,
  landscape,
}

enum PaperSizeType {
  a4,
  letter,
  legal,
}

class PrintSettings {
  final PageOrientationType orientation;
  final PaperSizeType paperSize;
  final bool showGridlines;
  final bool printHeaderRow;
  final String title;

  const PrintSettings({
    this.orientation = PageOrientationType.portrait,
    this.paperSize = PaperSizeType.a4,
    this.showGridlines = true,
    this.printHeaderRow = true,
    this.title = 'Green Excel Report',
  });

  PrintSettings copyWith({
    PageOrientationType? orientation,
    PaperSizeType? paperSize,
    bool? showGridlines,
    bool? printHeaderRow,
    String? title,
  }) {
    return PrintSettings(
      orientation: orientation ?? this.orientation,
      paperSize: paperSize ?? this.paperSize,
      showGridlines: showGridlines ?? this.showGridlines,
      printHeaderRow: printHeaderRow ?? this.printHeaderRow,
      title: title ?? this.title,
    );
  }
}

class PrintService {
  static Future<Uint8List> generatePdf(SheetData sheet, PrintSettings settings) async {
    final pdf = pw.Document();

    // Determine page format
    PdfPageFormat baseFormat;
    switch (settings.paperSize) {
      case PaperSizeType.letter:
        baseFormat = PdfPageFormat.letter;
        break;
      case PaperSizeType.legal:
        baseFormat = PdfPageFormat.legal;
        break;
      case PaperSizeType.a4:
      default:
        baseFormat = PdfPageFormat.a4;
        break;
    }

    final pageFormat = settings.orientation == PageOrientationType.landscape
        ? baseFormat.landscape
        : baseFormat.portrait;

    // Determine used bounding box (max row & max col containing data)
    int maxR = 0;
    int maxC = 0;
    sheet.cells.forEach((key, cell) {
      if (cell.computedValue.trim().isNotEmpty || cell.isCheckbox) {
        final colName = key.replaceAll(RegExp(r'[0-9]'), '');
        final rowNum = int.tryParse(key.replaceAll(RegExp(r'[A-Z]'), '')) ?? 1;
        final c = SheetData.colNameToIndex(colName);
        final r = rowNum - 1;
        if (r > maxR) maxR = r;
        if (c > maxC) maxC = c;
      }
    });

    maxR = (maxR < 5) ? 5 : maxR;
    maxC = (maxC < 4) ? 4 : (maxC > 12 ? 12 : maxC); // limit printable cols per page nicely

    final headers = List<String>.generate(maxC + 1, (i) => SheetData.indexToColName(i));
    final tableData = <List<String>>[];

    for (int r = 0; r <= maxR; r++) {
      final row = <String>[];
      for (int c = 0; c <= maxC; c++) {
        final cell = sheet.getCell(r, c);
        if (cell.isCheckbox) {
          row.add(cell.checked ? '[x]' : '[ ]');
        } else {
          row.add(FormulaEvaluator.formatDisplay(cell));
        }
      }
      tableData.add(row);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.green800, width: 2)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      settings.title,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                    pw.Text(
                      'Sheet: ${sheet.name} | Green Excel 2026 Pro',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Developer: Sachinthaka Sandaruwan',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                    ),
                    pw.Text(
                      'Green Soft Technologies',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by Green Excel Mobile', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          pw.TableHelper.fromTextArray(
            headers: settings.printHeaderRow ? headers : null,
            data: tableData,
            border: settings.showGridlines
                ? pw.TableBorder.all(color: PdfColors.grey400, width: 0.5)
                : null,
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<void> printDocument(SheetData sheet, PrintSettings settings) async {
    final pdfBytes = await generatePdf(sheet, settings);
    final tempDir = await getTemporaryDirectory();
    final fileName = '${settings.title.replaceAll(RegExp(r"[^a-zA-Z0-9_-]"), "_")}_${sheet.name}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Print / Save PDF: ${settings.title}');
  }

  static Future<void> sharePdf(SheetData sheet, PrintSettings settings) async {
    final pdfBytes = await generatePdf(sheet, settings);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${sheet.name}_report.pdf');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Exported from Green Excel 2026 Pro');
  }
}
