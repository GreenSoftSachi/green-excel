import 'package:flutter/material.dart';

enum CellNumberFormat {
  general,
  number,
  currencyUSD,
  currencyLKR,
  percentage,
  date,
}

enum CellBorderStyle {
  none,
  all,
  outside,
  bottomThick,
}

class CellStyle {
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final TextAlign alignment;
  final CellNumberFormat numberFormat;
  final CellBorderStyle borderStyle;

  const CellStyle({
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.fontSize = 13.0,
    this.textColor = const Color(0xFF212529),
    this.backgroundColor = Colors.white,
    this.alignment = TextAlign.left,
    this.numberFormat = CellNumberFormat.general,
    this.borderStyle = CellBorderStyle.none,
  });

  CellStyle copyWith({
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    TextAlign? alignment,
    CellNumberFormat? numberFormat,
    CellBorderStyle? borderStyle,
  }) {
    return CellStyle(
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      alignment: alignment ?? this.alignment,
      numberFormat: numberFormat ?? this.numberFormat,
      borderStyle: borderStyle ?? this.borderStyle,
    );
  }

  Map<String, dynamic> toJson() => {
        'isBold': isBold,
        'isItalic': isItalic,
        'isUnderline': isUnderline,
        'fontSize': fontSize,
        'textColor': textColor.value,
        'backgroundColor': backgroundColor.value,
        'alignment': alignment.index,
        'numberFormat': numberFormat.index,
        'borderStyle': borderStyle.index,
      };

  factory CellStyle.fromJson(Map<String, dynamic> json) => CellStyle(
        isBold: json['isBold'] ?? false,
        isItalic: json['isItalic'] ?? false,
        isUnderline: json['isUnderline'] ?? false,
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 13.0,
        textColor: Color(json['textColor'] ?? 0xFF212529),
        backgroundColor: Color(json['backgroundColor'] ?? 0xFFFFFFFF),
        alignment: TextAlign.values[json['alignment'] ?? 0],
        numberFormat: CellNumberFormat.values[json['numberFormat'] ?? 0],
        borderStyle: CellBorderStyle.values[json['borderStyle'] ?? 0],
      );
}

class CellData {
  String rawValue;
  String computedValue;
  bool isCheckbox;
  bool checked;
  CellStyle style;

  CellData({
    this.rawValue = '',
    this.computedValue = '',
    this.isCheckbox = false,
    this.checked = false,
    CellStyle? style,
  }) : style = style ?? const CellStyle();

  bool get isFormula => rawValue.startsWith('=');

  CellData copy() {
    return CellData(
      rawValue: rawValue,
      computedValue: computedValue,
      isCheckbox: isCheckbox,
      checked: checked,
      style: style.copyWith(),
    );
  }

  Map<String, dynamic> toJson() => {
        'rawValue': rawValue,
        'computedValue': computedValue,
        'isCheckbox': isCheckbox,
        'checked': checked,
        'style': style.toJson(),
      };

  factory CellData.fromJson(Map<String, dynamic> json) => CellData(
        rawValue: json['rawValue'] ?? '',
        computedValue: json['computedValue'] ?? '',
        isCheckbox: json['isCheckbox'] ?? false,
        checked: json['checked'] ?? false,
        style: json['style'] != null
            ? CellStyle.fromJson(json['style'])
            : const CellStyle(),
      );
}
