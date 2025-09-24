import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;

String alignmentToString(pw.CrossAxisAlignment alignment) {
  if (alignment == pw.CrossAxisAlignment.start) return 'start';
  if (alignment == pw.CrossAxisAlignment.center) return 'center';
  if (alignment == pw.CrossAxisAlignment.end) return 'end';
  return 'start';
}

pw.CrossAxisAlignment alignmentFromString(String alignmentStr) {
  switch (alignmentStr) {
    case 'center':
      return pw.CrossAxisAlignment.center;
    case 'end':
      return pw.CrossAxisAlignment.end;
    case 'start':
    default:
      return pw.CrossAxisAlignment.start;
  }
}

class PrintStyle {
  final double fontSize;
  final bool isBold;
  final pw.CrossAxisAlignment alignment;

  PrintStyle({
    required this.fontSize,
    required this.isBold,
    required this.alignment,
  });

  PrintStyle copyWith({
    double? fontSize,
    bool? isBold,
    pw.CrossAxisAlignment? alignment,
  }) {
    return PrintStyle(
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      alignment: alignment ?? this.alignment,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'isBold': isBold,
      'alignment': alignmentToString(alignment),
    };
  }

  factory PrintStyle.fromJson(Map<String, dynamic> json) {
    return PrintStyle(
      fontSize: (json['fontSize'] as num? ?? 10.0).toDouble(),
      isBold: json['isBold'] as bool? ?? false,
      alignment: alignmentFromString(json['alignment'] as String? ?? 'start'),
    );
  }
}

class PrintTemplateSettings {
  final PrintStyle headerStyle;
  final PrintStyle tableStyle;
  final PrintStyle orderInfoStyle;
  final PrintStyle itemStyle;
  final String footerText;
  final PrintStyle footerStyle;

  PrintTemplateSettings({
    required this.headerStyle,
    required this.tableStyle,
    required this.orderInfoStyle,
    required this.itemStyle,
    required this.footerText,
    required this.footerStyle,
  });

  factory PrintTemplateSettings.defaults() {
    return PrintTemplateSettings(
      headerStyle: PrintStyle(fontSize: 14, isBold: true, alignment: pw.CrossAxisAlignment.center),
      tableStyle: PrintStyle(fontSize: 12, isBold: true, alignment: pw.CrossAxisAlignment.center),
      orderInfoStyle: PrintStyle(fontSize: 9, isBold: false, alignment: pw.CrossAxisAlignment.center),
      itemStyle: PrintStyle(fontSize: 8, isBold: true, alignment: pw.CrossAxisAlignment.start),
      footerText: '',
      footerStyle: PrintStyle(fontSize: 8, isBold: false, alignment: pw.CrossAxisAlignment.center),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'headerStyle': headerStyle.toJson(),
      'tableStyle': tableStyle.toJson(),
      'orderInfoStyle': orderInfoStyle.toJson(),
      'itemStyle': itemStyle.toJson(),
      'footerText': footerText,
      'footerStyle': footerStyle.toJson(),
    };
  }

  factory PrintTemplateSettings.fromJson(Map<String, dynamic> json) {
    return PrintTemplateSettings(
      headerStyle: PrintStyle.fromJson(json['headerStyle'] ?? {}),
      tableStyle: PrintStyle.fromJson(json['tableStyle'] ?? {}),
      orderInfoStyle: PrintStyle.fromJson(json['orderInfoStyle'] ?? {}),
      itemStyle: PrintStyle.fromJson(json['itemStyle'] ?? {}),
      footerText: json['footerText'] ?? '',
      footerStyle: PrintStyle.fromJson(json['footerStyle'] ?? {}),
    );
  }
}

class ReceiptTemplateSettings {
  final PrintStyle headerStyle;
  final String subtitleText;
  final PrintStyle subtitleStyle;
  final String addressText;
  final PrintStyle addressStyle;
  final String phoneText;
  final PrintStyle phoneStyle;
  final PrintStyle infoStyle;
  final PrintStyle itemStyle;
  final PrintStyle totalStyle;
  final String finalMessageText;
  final PrintStyle finalMessageStyle;

  ReceiptTemplateSettings({
    required this.headerStyle,
    required this.subtitleText,
    required this.subtitleStyle,
    required this.addressText,
    required this.addressStyle,
    required this.phoneText,
    required this.phoneStyle,
    required this.infoStyle,
    required this.itemStyle,
    required this.totalStyle,
    required this.finalMessageText,
    required this.finalMessageStyle,
  });

  factory ReceiptTemplateSettings.defaults() {
    return ReceiptTemplateSettings(
      headerStyle: PrintStyle(fontSize: 16, isBold: true, alignment: pw.CrossAxisAlignment.center),
      subtitleText: 'CNPJ: 00.000.000/0001-00',
      subtitleStyle: PrintStyle(fontSize: 10, isBold: false, alignment: pw.CrossAxisAlignment.center),
      addressText: 'Rua Exemplo, 123, Bairro, Cidade-UF',
      addressStyle: PrintStyle(fontSize: 10, isBold: false, alignment: pw.CrossAxisAlignment.center),
      phoneText: 'Telefone: (00) 00000-0000',
      phoneStyle: PrintStyle(fontSize: 10, isBold: false, alignment: pw.CrossAxisAlignment.center),
      infoStyle: PrintStyle(fontSize: 10, isBold: false, alignment: pw.CrossAxisAlignment.center),
      itemStyle: PrintStyle(fontSize: 10, isBold: false, alignment: pw.CrossAxisAlignment.start),
      totalStyle: PrintStyle(fontSize: 14, isBold: true, alignment: pw.CrossAxisAlignment.start),
      finalMessageText: 'Obrigado pela preferência!',
      finalMessageStyle: PrintStyle(fontSize: 10, isBold: false, alignment: pw.CrossAxisAlignment.center),
    );
  }

  Map<String, dynamic> toJson() => {
    'headerStyle': headerStyle.toJson(),
    'subtitleText': subtitleText,
    'subtitleStyle': subtitleStyle.toJson(),
    'addressText': addressText,
    'addressStyle': addressStyle.toJson(),
    'phoneText': phoneText,
    'phoneStyle': phoneStyle.toJson(),
    'infoStyle': infoStyle.toJson(),
    'itemStyle': itemStyle.toJson(),
    'totalStyle': totalStyle.toJson(),
    'finalMessageText': finalMessageText,
    'finalMessageStyle': finalMessageStyle.toJson(),
  };

  factory ReceiptTemplateSettings.fromJson(Map<String, dynamic> json) => ReceiptTemplateSettings(
    headerStyle: PrintStyle.fromJson(json['headerStyle'] ?? {}),
    subtitleText: json['subtitleText'] ?? '',
    subtitleStyle: PrintStyle.fromJson(json['subtitleStyle'] ?? {}),
    addressText: json['addressText'] ?? '',
    addressStyle: PrintStyle.fromJson(json['addressStyle'] ?? {}),
    phoneText: json['phoneText'] ?? '',
    phoneStyle: PrintStyle.fromJson(json['phoneStyle'] ?? {}),
    infoStyle: PrintStyle.fromJson(json['infoStyle'] ?? {}),
    itemStyle: PrintStyle.fromJson(json['itemStyle'] ?? {}),
    totalStyle: PrintStyle.fromJson(json['totalStyle'] ?? {}),
    finalMessageText: json['finalMessageText'] ?? 'Obrigado pela preferência!',
    finalMessageStyle: PrintStyle.fromJson(json['finalMessageStyle'] ?? {}),
  );
}