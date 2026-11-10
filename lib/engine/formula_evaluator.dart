import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../models/cell_data.dart';
import '../models/sheet_data.dart';

class FormulaEvaluator {
  static final RegExp _cellRegex = RegExp(r'^[A-Z]+[0-9]+$');
  static final RegExp _rangeRegex = RegExp(r'^([A-Z]+[0-9]+):([A-Z]+[0-9]+)$');

  static void evaluateAll(SheetData sheet) {
    // Two passes to resolve dependencies
    for (int pass = 0; pass < 2; pass++) {
      sheet.cells.forEach((key, cell) {
        if (cell.isCheckbox) {
          cell.computedValue = cell.checked ? 'TRUE' : 'FALSE';
        } else if (cell.rawValue.startsWith('=')) {
          cell.computedValue = evaluateFormula(cell.rawValue, sheet);
        } else {
          cell.computedValue = cell.rawValue;
        }
      });
    }
  }

  static String formatDisplay(CellData cell) {
    if (cell.isCheckbox) return '';
    final val = cell.computedValue;
    if (val.isEmpty) return '';

    final numVal = double.tryParse(val.replaceAll(',', '').replaceAll('\$', '').replaceAll('Rs.', '').trim());

    if (numVal != null) {
      switch (cell.style.numberFormat) {
        case CellNumberFormat.currencyUSD:
          final f = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
          return f.format(numVal);
        case CellNumberFormat.currencyLKR:
          final f = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
          return f.format(numVal);
        case CellNumberFormat.percentage:
          final f = NumberFormat.percentPattern();
          return f.format(numVal > 1.0 ? numVal / 100 : numVal);
        case CellNumberFormat.number:
          final f = NumberFormat('#,##0.00');
          return f.format(numVal);
        case CellNumberFormat.date:
          try {
            final dt = DateTime.fromMillisecondsSinceEpoch(numVal.toInt());
            return DateFormat('yyyy-MM-dd').format(dt);
          } catch (_) {
            return val;
          }
        case CellNumberFormat.general:
        default:
          if (numVal == numVal.toInt()) {
            return numVal.toInt().toString();
          }
          return numVal.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
      }
    }
    return val;
  }

  static String evaluateFormula(String formulaStr, SheetData sheet) {
    try {
      String expr = formulaStr.trim();
      if (expr.startsWith('=')) {
        expr = expr.substring(1).trim();
      }

      if (expr.isEmpty) return '';

      // Check for Python in Excel 2026: =PY(...)
      if (expr.toUpperCase().startsWith('PY(') && expr.endsWith(')')) {
        final pyCode = expr.substring(3, expr.length - 1).trim();
        return _evalPython(pyCode, sheet);
      }

      // Check for Regex 2026 functions
      if (expr.toUpperCase().startsWith('REGEXTEST(')) {
        return _evalRegexTest(expr, sheet);
      }
      if (expr.toUpperCase().startsWith('REGEXEXTRACT(')) {
        return _evalRegexExtract(expr, sheet);
      }
      if (expr.toUpperCase().startsWith('REGEXREPLACE(')) {
        return _evalRegexReplace(expr, sheet);
      }

      // Check for Modern XLOOKUP
      if (expr.toUpperCase().startsWith('XLOOKUP(')) {
        return _evalXlookup(expr, sheet);
      }

      // Check for Standard VLOOKUP
      if (expr.toUpperCase().startsWith('VLOOKUP(')) {
        return _evalVlookup(expr, sheet);
      }

      // Check for Dynamic Array UNIQUE & SORT
      if (expr.toUpperCase().startsWith('UNIQUE(')) {
        return _evalUnique(expr, sheet);
      }
      if (expr.toUpperCase().startsWith('SORT(')) {
        return _evalSort(expr, sheet);
      }
      if (expr.toUpperCase().startsWith('SEQUENCE(')) {
        return _evalSequence(expr);
      }

      // Check for Math & Aggregate functions
      final funcMatch = RegExp(r'^([A-Z0-9]+)\((.*)\)$', caseSensitive: false).firstMatch(expr);
      if (funcMatch != null) {
        final funcName = funcMatch.group(1)!.toUpperCase();
        final argsStr = funcMatch.group(2)!;
        return _evalFunction(funcName, argsStr, sheet);
      }

      // Try simple arithmetic expression
      return _evalSimpleMath(expr, sheet);
    } catch (e) {
      return '#VALUE!';
    }
  }

  static String _evalFunction(String funcName, String argsStr, SheetData sheet) {
    final args = _splitArguments(argsStr);

    switch (funcName) {
      case 'SUM':
        final values = _getRangeOrArgDoubles(args, sheet);
        final sum = values.fold<double>(0.0, (prev, element) => prev + element);
        return _formatDouble(sum);

      case 'AVERAGE':
        final values = _getRangeOrArgDoubles(args, sheet);
        if (values.isEmpty) return '#DIV/0!';
        final sum = values.fold<double>(0.0, (prev, element) => prev + element);
        return _formatDouble(sum / values.length);

      case 'COUNT':
        final values = _getRangeOrArgDoubles(args, sheet);
        return values.length.toString();

      case 'COUNTA':
        final strings = _getRangeOrArgStrings(args, sheet);
        final count = strings.where((s) => s.trim().isNotEmpty).length;
        return count.toString();

      case 'MIN':
        final values = _getRangeOrArgDoubles(args, sheet);
        if (values.isEmpty) return '0';
        return _formatDouble(values.reduce(math.min));

      case 'MAX':
        final values = _getRangeOrArgDoubles(args, sheet);
        if (values.isEmpty) return '0';
        return _formatDouble(values.reduce(math.max));

      case 'ROUND':
        if (args.isEmpty) return '#VALUE!';
        final val = _resolveDouble(args[0], sheet);
        final decimals = args.length > 1 ? _resolveDouble(args[1], sheet).toInt() : 0;
        final mod = math.pow(10, decimals).toDouble();
        final rounded = (val * mod).roundToDouble() / mod;
        return _formatDouble(rounded);

      case 'PRODUCT':
        final values = _getRangeOrArgDoubles(args, sheet);
        if (values.isEmpty) return '0';
        final prod = values.fold<double>(1.0, (p, el) => p * el);
        return _formatDouble(prod);

      case 'POWER':
        if (args.length < 2) return '#VALUE!';
        final b = _resolveDouble(args[0], sheet);
        final exp = _resolveDouble(args[1], sheet);
        return _formatDouble(math.pow(b, exp).toDouble());

      case 'SQRT':
        if (args.isEmpty) return '#VALUE!';
        final val = _resolveDouble(args[0], sheet);
        if (val < 0) return '#NUM!';
        return _formatDouble(math.sqrt(val));

      case 'ABS':
        if (args.isEmpty) return '#VALUE!';
        return _formatDouble(_resolveDouble(args[0], sheet).abs());

      case 'MOD':
        if (args.length < 2) return '#VALUE!';
        final n = _resolveDouble(args[0], sheet);
        final d = _resolveDouble(args[1], sheet);
        if (d == 0) return '#DIV/0!';
        return _formatDouble(n % d);

      case 'IF':
        if (args.length < 2) return '#VALUE!';
        final conditionStr = args[0];
        final isTrue = _evalCondition(conditionStr, sheet);
        if (isTrue) {
          return _resolveValue(args[1], sheet);
        } else {
          return args.length > 2 ? _resolveValue(args[2], sheet) : 'FALSE';
        }

      case 'IFS':
        for (int i = 0; i < args.length - 1; i += 2) {
          if (_evalCondition(args[i], sheet)) {
            return _resolveValue(args[i + 1], sheet);
          }
        }
        return '#N/A';

      case 'AND':
        for (final arg in args) {
          if (!_evalCondition(arg, sheet)) return 'FALSE';
        }
        return 'TRUE';

      case 'OR':
        for (final arg in args) {
          if (_evalCondition(arg, sheet)) return 'TRUE';
        }
        return 'FALSE';

      case 'NOT':
        if (args.isEmpty) return '#VALUE!';
        return _evalCondition(args[0], sheet) ? 'FALSE' : 'TRUE';

      case 'CONCAT':
      case 'CONCATENATE':
        final sb = StringBuffer();
        for (final arg in args) {
          sb.write(_resolveValue(arg, sheet));
        }
        return sb.toString();

      case 'UPPER':
        if (args.isEmpty) return '';
        return _resolveValue(args[0], sheet).toUpperCase();

      case 'LOWER':
        if (args.isEmpty) return '';
        return _resolveValue(args[0], sheet).toLowerCase();

      case 'LEN':
        if (args.isEmpty) return '0';
        return _resolveValue(args[0], sheet).length.toString();

      case 'TRIM':
        if (args.isEmpty) return '';
        return _resolveValue(args[0], sheet).trim();

      case 'LEFT':
        if (args.isEmpty) return '';
        final s = _resolveValue(args[0], sheet);
        final len = args.length > 1 ? _resolveDouble(args[1], sheet).toInt() : 1;
        return s.substring(0, math.min(len, s.length));

      case 'RIGHT':
        if (args.isEmpty) return '';
        final s = _resolveValue(args[0], sheet);
        final len = args.length > 1 ? _resolveDouble(args[1], sheet).toInt() : 1;
        return s.substring(math.max(0, s.length - len));

      case 'TODAY':
        return DateFormat('yyyy-MM-dd').format(DateTime.now());

      case 'NOW':
        return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

      default:
        return '#NAME?';
    }
  }

  // 2026 REGEX Functions
  static String _evalRegexTest(String expr, SheetData sheet) {
    final args = _splitArguments(expr.substring(10, expr.length - 1));
    if (args.length < 2) return '#VALUE!';
    final text = _resolveValue(args[0], sheet);
    final pattern = _stripQuotes(_resolveValue(args[1], sheet));
    try {
      final reg = RegExp(pattern);
      return reg.hasMatch(text) ? 'TRUE' : 'FALSE';
    } catch (_) {
      return '#VALUE!';
    }
  }

  static String _evalRegexExtract(String expr, SheetData sheet) {
    final args = _splitArguments(expr.substring(13, expr.length - 1));
    if (args.length < 2) return '#VALUE!';
    final text = _resolveValue(args[0], sheet);
    final pattern = _stripQuotes(_resolveValue(args[1], sheet));
    try {
      final reg = RegExp(pattern);
      final match = reg.firstMatch(text);
      if (match == null) return '#N/A';
      return match.groupCount > 0 ? (match.group(1) ?? match.group(0) ?? '') : (match.group(0) ?? '');
    } catch (_) {
      return '#VALUE!';
    }
  }

  static String _evalRegexReplace(String expr, SheetData sheet) {
    final args = _splitArguments(expr.substring(13, expr.length - 1));
    if (args.length < 3) return '#VALUE!';
    final text = _resolveValue(args[0], sheet);
    final pattern = _stripQuotes(_resolveValue(args[1], sheet));
    final replacement = _stripQuotes(_resolveValue(args[2], sheet));
    try {
      final reg = RegExp(pattern);
      return text.replaceAll(reg, replacement);
    } catch (_) {
      return '#VALUE!';
    }
  }

  // 2026 XLOOKUP Function
  static String _evalXlookup(String expr, SheetData sheet) {
    final args = _splitArguments(expr.substring(8, expr.length - 1));
    if (args.length < 3) return '#VALUE!';
    final lookupVal = _resolveValue(args[0], sheet).toLowerCase();
    final lookupRange = _expandRange(args[1].trim());
    final returnRange = _expandRange(args[2].trim());
    final ifNotFound = args.length > 3 ? _resolveValue(args[3], sheet) : '#N/A';

    for (int i = 0; i < lookupRange.length; i++) {
      final cellKey = lookupRange[i];
      final val = (sheet.getCellByKey(cellKey)?.computedValue ?? '').toLowerCase();
      if (val == lookupVal || val.contains(lookupVal)) {
        if (i < returnRange.length) {
          return sheet.getCellByKey(returnRange[i])?.computedValue ?? '';
        }
      }
    }
    return ifNotFound;
  }

  // Standard VLOOKUP Function
  static String _evalVlookup(String expr, SheetData sheet) {
    final args = _splitArguments(expr.substring(8, expr.length - 1));
    if (args.length < 3) return '#VALUE!';
    final lookupVal = _resolveValue(args[0], sheet).toLowerCase();
    final rangeStr = args[1].trim();
    final colIdx = _resolveDouble(args[2], sheet).toInt();

    final parts = rangeStr.split(':');
    if (parts.length != 2) return '#REF!';
    final startCol = SheetData.colNameToIndex(parts[0].replaceAll(RegExp(r'[0-9]'), ''));
    final startRow = int.parse(parts[0].replaceAll(RegExp(r'[A-Z]'), '')) - 1;
    final endRow = int.parse(parts[1].replaceAll(RegExp(r'[A-Z]'), '')) - 1;

    for (int r = startRow; r <= endRow; r++) {
      final firstCell = sheet.getCell(r, startCol);
      if (firstCell.computedValue.toLowerCase() == lookupVal) {
        final targetCell = sheet.getCell(r, startCol + colIdx - 1);
        return targetCell.computedValue;
      }
    }
    return '#N/A';
  }

  // Dynamic Array helpers
  static String _evalUnique(String expr, SheetData sheet) {
    final rangeStr = expr.substring(7, expr.length - 1).trim();
    final cells = _expandRange(rangeStr);
    final set = <String>{};
    for (final c in cells) {
      final v = sheet.getCellByKey(c)?.computedValue ?? '';
      if (v.isNotEmpty) set.add(v);
    }
    return set.join(', ');
  }

  static String _evalSort(String expr, SheetData sheet) {
    final rangeStr = expr.substring(5, expr.length - 1).trim();
    final cells = _expandRange(rangeStr);
    final list = <String>[];
    for (final c in cells) {
      final v = sheet.getCellByKey(c)?.computedValue ?? '';
      if (v.isNotEmpty) list.add(v);
    }
    list.sort();
    return list.join(', ');
  }

  static String _evalSequence(String expr) {
    final args = _splitArguments(expr.substring(9, expr.length - 1));
    final count = int.tryParse(args[0].trim()) ?? 5;
    return List.generate(count, (i) => (i + 1).toString()).join(', ');
  }

  // Python in Excel 2026 Simulator
  static String _evalPython(String code, SheetData sheet) {
    try {
      // Handle python sum([1, 2, 3])
      if (code.contains('sum(')) {
        final m = RegExp(r'sum\(\[(.*)\]\)').firstMatch(code);
        if (m != null) {
          final items = m.group(1)!.split(',').map((e) => double.tryParse(e.trim()) ?? 0.0);
          final s = items.fold<double>(0.0, (a, b) => a + b);
          return _formatDouble(s);
        }
      }
      // Handle len("text")
      if (code.contains('len(')) {
        final m = RegExp(r'len\(["\x27](.*)["\x27]\)').firstMatch(code);
        if (m != null) {
          return m.group(1)!.length.toString();
        }
      }
      // Handle string manipulation or math
      return _evalSimpleMath(code, sheet);
    } catch (_) {
      return '#PY_ERR';
    }
  }

  static String _evalSimpleMath(String expr, SheetData sheet) {
    // Replace cell references with numbers
    String parsed = expr;
    final cellMatches = RegExp(r'\b([A-Z]+[0-9]+)\b').allMatches(expr);
    for (final m in cellMatches) {
      final key = m.group(1)!;
      final cell = sheet.getCellByKey(key);
      final val = cell?.computedValue ?? '0';
      final cleanVal = double.tryParse(val.replaceAll('\$', '').replaceAll('Rs.', '').trim()) ?? 0;
      parsed = parsed.replaceAll(key, cleanVal.toString());
    }

    // Evaluate basic math (+, -, *, /)
    try {
      final result = _calculateMathString(parsed);
      return _formatDouble(result);
    } catch (_) {
      return expr;
    }
  }

  static double _calculateMathString(String expression) {
    String exp = expression.replaceAll(' ', '');
    // Handle brackets
    while (exp.contains('(')) {
      final start = exp.lastIndexOf('(');
      final end = exp.indexOf(')', start);
      if (end == -1) break;
      final inside = exp.substring(start + 1, end);
      final val = _calculateMathString(inside);
      exp = exp.replaceRange(start, end + 1, val.toString());
    }

    // Addition & subtraction
    List<String> addTokens = [];
    List<String> ops = [];
    int lastIdx = 0;
    for (int i = 0; i < exp.length; i++) {
      if ((exp[i] == '+' || exp[i] == '-') && i > 0 && exp[i - 1] != '*' && exp[i - 1] != '/') {
        addTokens.add(exp.substring(lastIdx, i));
        ops.add(exp[i]);
        lastIdx = i + 1;
      }
    }
    addTokens.add(exp.substring(lastIdx));

    double total = _evalMulDiv(addTokens[0]);
    for (int i = 0; i < ops.length; i++) {
      final nextVal = _evalMulDiv(addTokens[i + 1]);
      if (ops[i] == '+') total += nextVal;
      if (ops[i] == '-') total -= nextVal;
    }
    return total;
  }

  static double _evalMulDiv(String s) {
    final tokens = <String>[];
    final ops = <String>[];
    int lastIdx = 0;
    for (int i = 0; i < s.length; i++) {
      if (s[i] == '*' || s[i] == '/') {
        tokens.add(s.substring(lastIdx, i));
        ops.add(s[i]);
        lastIdx = i + 1;
      }
    }
    tokens.add(s.substring(lastIdx));

    double res = double.tryParse(tokens[0]) ?? 0.0;
    for (int i = 0; i < ops.length; i++) {
      final val = double.tryParse(tokens[i + 1]) ?? 1.0;
      if (ops[i] == '*') res *= val;
      if (ops[i] == '/') {
        if (val == 0) throw Exception('Div by zero');
        res /= val;
      }
    }
    return res;
  }

  static bool _evalCondition(String cond, SheetData sheet) {
    cond = cond.trim();
    if (cond.toUpperCase() == 'TRUE') return true;
    if (cond.toUpperCase() == 'FALSE') return false;

    final ops = ['>=', '<=', '<>', '!=', '==', '=', '>', '<'];
    for (final op in ops) {
      if (cond.contains(op)) {
        final parts = cond.split(op);
        final left = _resolveDouble(parts[0], sheet);
        final right = _resolveDouble(parts[1], sheet);
        switch (op) {
          case '>=': return left >= right;
          case '<=': return left <= right;
          case '<>':
          case '!=': return left != right;
          case '==':
          case '=': return left == right;
          case '>': return left > right;
          case '<': return left < right;
        }
      }
    }
    return _resolveDouble(cond, sheet) != 0;
  }

  static List<String> _splitArguments(String argsStr) {
    final args = <String>[];
    int depth = 0;
    int lastIdx = 0;
    for (int i = 0; i < argsStr.length; i++) {
      final char = argsStr[i];
      if (char == '(') depth++;
      if (char == ')') depth--;
      if (char == ',' && depth == 0) {
        args.add(argsStr.substring(lastIdx, i).trim());
        lastIdx = i + 1;
      }
    }
    if (lastIdx < argsStr.length) {
      args.add(argsStr.substring(lastIdx).trim());
    }
    return args;
  }

  static List<double> _getRangeOrArgDoubles(List<String> args, SheetData sheet) {
    final list = <double>[];
    for (final arg in args) {
      if (_rangeRegex.hasMatch(arg)) {
        final cells = _expandRange(arg);
        for (final c in cells) {
          final cell = sheet.getCellByKey(c);
          if (cell != null && cell.computedValue.isNotEmpty) {
            final val = double.tryParse(cell.computedValue.replaceAll('\$', '').replaceAll('Rs.', '').trim());
            if (val != null) list.add(val);
          }
        }
      } else {
        list.add(_resolveDouble(arg, sheet));
      }
    }
    return list;
  }

  static List<String> _getRangeOrArgStrings(List<String> args, SheetData sheet) {
    final list = <String>[];
    for (final arg in args) {
      if (_rangeRegex.hasMatch(arg)) {
        final cells = _expandRange(arg);
        for (final c in cells) {
          final cell = sheet.getCellByKey(c);
          if (cell != null) list.add(cell.computedValue);
        }
      } else {
        list.add(_resolveValue(arg, sheet));
      }
    }
    return list;
  }

  static List<String> _expandRange(String rangeStr) {
    final match = _rangeRegex.firstMatch(rangeStr.toUpperCase());
    if (match == null) return [rangeStr.toUpperCase()];

    final start = match.group(1)!;
    final end = match.group(2)!;

    final startCol = SheetData.colNameToIndex(start.replaceAll(RegExp(r'[0-9]'), ''));
    final startRow = int.parse(start.replaceAll(RegExp(r'[A-Z]'), '')) - 1;
    final endCol = SheetData.colNameToIndex(end.replaceAll(RegExp(r'[0-9]'), ''));
    final endRow = int.parse(end.replaceAll(RegExp(r'[A-Z]'), '')) - 1;

    final result = <String>[];
    final minR = math.min(startRow, endRow);
    final maxR = math.max(startRow, endRow);
    final minC = math.min(startCol, endCol);
    final maxC = math.max(startCol, endCol);

    for (int r = minR; r <= maxR; r++) {
      for (int c = minC; c <= maxC; c++) {
        result.add(SheetData.cellKey(r, c));
      }
    }
    return result;
  }

  static String _resolveValue(String token, SheetData sheet) {
    token = token.trim();
    if (token.startsWith('"') && token.endsWith('"')) {
      return token.substring(1, token.length - 1);
    }
    if (_cellRegex.hasMatch(token.toUpperCase())) {
      final cell = sheet.getCellByKey(token.toUpperCase());
      return cell?.computedValue ?? '';
    }
    return token;
  }

  static double _resolveDouble(String token, SheetData sheet) {
    final valStr = _resolveValue(token, sheet);
    return double.tryParse(valStr.replaceAll('\$', '').replaceAll('Rs.', '').trim()) ?? 0.0;
  }

  static String _stripQuotes(String s) {
    if (s.startsWith('"') && s.endsWith('"') && s.length >= 2) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }

  static String _formatDouble(double d) {
    if (d.isNaN || d.isInfinite) return '#NUM!';
    if (d == d.toInt()) return d.toInt().toString();
    return d.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
  }
}
