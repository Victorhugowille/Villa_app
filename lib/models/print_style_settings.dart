import 'package:flutter/material.dart' show CrossAxisAlignment;

// Funções utilitárias para converter CrossAxisAlignment para e de String
String alignmentToString(CrossAxisAlignment alignment) {
  if (alignment == CrossAxisAlignment.center) return 'center';
  if (alignment == CrossAxisAlignment.end) return 'end';
  return 'start';
}

CrossAxisAlignment alignmentFromString(String alignmentStr) {
  switch (alignmentStr) {
    case 'center':
      return CrossAxisAlignment.center;
    case 'end':
      return CrossAxisAlignment.end;
    case 'start':
    default:
      return CrossAxisAlignment.start;
  }
}

class PrintStyle {
  final double fontSize;
  final bool isBold;
  final CrossAxisAlignment alignment;

  PrintStyle({
    required this.fontSize,
    required this.isBold,
    required this.alignment,
  });

  PrintStyle copyWith({
    double? fontSize,
    bool? isBold,
    CrossAxisAlignment? alignment,
  }) {
    return PrintStyle(
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      alignment: alignment ?? this.alignment,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'isBold': isBold,
        'alignment': alignmentToString(alignment),
      };

  factory PrintStyle.fromJson(Map<String, dynamic> json) => PrintStyle(
        fontSize: (json['fontSize'] as num? ?? 10.0).toDouble(),
        isBold: json['isBold'] as bool? ?? false,
        alignment: alignmentFromString(json['alignment'] as String? ?? 'start'),
      );
}

class KitchenTemplateSettings {
  final PrintStyle headerStyle;
  final PrintStyle tableStyle;
  final PrintStyle orderInfoStyle;
  final PrintStyle itemStyle;
  final String footerText;
  final PrintStyle footerStyle;
  final String? logoPath;
  final double logoHeight;
  final CrossAxisAlignment logoAlignment; // Novo campo para alinhamento do logo

  KitchenTemplateSettings({
    required this.headerStyle,
    required this.tableStyle,
    required this.orderInfoStyle,
    required this.itemStyle,
    required this.footerText,
    required this.footerStyle,
    this.logoPath,
    this.logoHeight = 40.0,
    required this.logoAlignment, // Inicialização
  });

  KitchenTemplateSettings copyWith({
    PrintStyle? headerStyle,
    PrintStyle? tableStyle,
    PrintStyle? orderInfoStyle,
    PrintStyle? itemStyle,
    String? footerText,
    PrintStyle? footerStyle,
    String? logoPath,
    double? logoHeight,
    CrossAxisAlignment? logoAlignment, // Para o copyWith
  }) {
    return KitchenTemplateSettings(
      headerStyle: headerStyle ?? this.headerStyle,
      tableStyle: tableStyle ?? this.tableStyle,
      orderInfoStyle: orderInfoStyle ?? this.orderInfoStyle,
      itemStyle: itemStyle ?? this.itemStyle,
      footerText: footerText ?? this.footerText,
      footerStyle: footerStyle ?? this.footerStyle,
      logoPath: logoPath ?? this.logoPath,
      logoHeight: logoHeight ?? this.logoHeight,
      logoAlignment: logoAlignment ?? this.logoAlignment, // Aplica o novo campo
    );
  }

  factory KitchenTemplateSettings.defaults() => KitchenTemplateSettings(
        headerStyle: PrintStyle(
            fontSize: 14, isBold: true, alignment: CrossAxisAlignment.center),
        tableStyle: PrintStyle(
            fontSize: 16, isBold: true, alignment: CrossAxisAlignment.center),
        orderInfoStyle: PrintStyle(
            fontSize: 10, isBold: false, alignment: CrossAxisAlignment.center),
        itemStyle: PrintStyle(
            fontSize: 10, isBold: true, alignment: CrossAxisAlignment.start),
        footerText: 'Obrigado!',
        footerStyle: PrintStyle(
            fontSize: 10, isBold: false, alignment: CrossAxisAlignment.center),
        logoPath: null,
        logoHeight: 40.0,
        logoAlignment: CrossAxisAlignment.center, // Valor padrão
      );

  factory KitchenTemplateSettings.fromJson(Map<String, dynamic> json) =>
      KitchenTemplateSettings(
        headerStyle: PrintStyle.fromJson(json['headerStyle'] ?? {}),
        tableStyle: PrintStyle.fromJson(json['tableStyle'] ?? {}),
        orderInfoStyle: PrintStyle.fromJson(json['orderInfoStyle'] ?? {}),
        itemStyle: PrintStyle.fromJson(json['itemStyle'] ?? {}),
        footerText: json['footerText'] ?? 'Obrigado!',
        footerStyle: PrintStyle.fromJson(json['footerStyle'] ?? {}),
        logoPath: json['logoPath'],
        logoHeight: (json['logoHeight'] as num? ?? 40.0).toDouble(),
        logoAlignment:
            alignmentFromString(json['logoAlignment'] as String? ?? 'center'), // Desserialização
      );

  Map<String, dynamic> toJson() => {
        'headerStyle': headerStyle.toJson(),
        'tableStyle': tableStyle.toJson(),
        'orderInfoStyle': orderInfoStyle.toJson(),
        'itemStyle': itemStyle.toJson(),
        'footerText': footerText,
        'footerStyle': footerStyle.toJson(),
        'logoPath': logoPath,
        'logoHeight': logoHeight,
        'logoAlignment': alignmentToString(logoAlignment), // Serialização
      };
}

class ReceiptTemplateSettings {
  final String? logoPath;
  final double logoHeight;
  final CrossAxisAlignment logoAlignment; // Novo campo para alinhamento do logo
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
    this.logoPath,
    this.logoHeight = 40.0,
    required this.logoAlignment, // Inicialização
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

  ReceiptTemplateSettings copyWith({
    String? logoPath,
    double? logoHeight,
    CrossAxisAlignment? logoAlignment, // Para o copyWith
    PrintStyle? headerStyle,
    String? subtitleText,
    PrintStyle? subtitleStyle,
    String? addressText,
    PrintStyle? addressStyle,
    String? phoneText,
    PrintStyle? phoneStyle,
    PrintStyle? infoStyle,
    PrintStyle? itemStyle,
    PrintStyle? totalStyle,
    String? finalMessageText,
    PrintStyle? finalMessageStyle,
  }) {
    return ReceiptTemplateSettings(
      logoPath: logoPath ?? this.logoPath,
      logoHeight: logoHeight ?? this.logoHeight,
      logoAlignment: logoAlignment ?? this.logoAlignment, // Aplica o novo campo
      headerStyle: headerStyle ?? this.headerStyle,
      subtitleText: subtitleText ?? this.subtitleText,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      addressText: addressText ?? this.addressText,
      addressStyle: addressStyle ?? this.addressStyle,
      phoneText: phoneText ?? this.phoneText,
      phoneStyle: phoneStyle ?? this.phoneStyle,
      infoStyle: infoStyle ?? this.infoStyle,
      itemStyle: itemStyle ?? this.itemStyle,
      totalStyle: totalStyle ?? this.totalStyle,
      finalMessageText: finalMessageText ?? this.finalMessageText,
      finalMessageStyle: finalMessageStyle ?? this.finalMessageStyle,
    );
  }

  factory ReceiptTemplateSettings.defaults() {
    return ReceiptTemplateSettings(
      logoPath: null,
      logoHeight: 40.0,
      logoAlignment: CrossAxisAlignment.center, // Valor padrão
      headerStyle: PrintStyle(
          fontSize: 16, isBold: true, alignment: CrossAxisAlignment.center),
      subtitleText: 'CNPJ: 00.000.000/0001-00',
      subtitleStyle: PrintStyle(
          fontSize: 10, isBold: false, alignment: CrossAxisAlignment.center),
      addressText: 'Rua Exemplo, 123, Bairro, Cidade-UF',
      addressStyle: PrintStyle(
          fontSize: 10, isBold: false, alignment: CrossAxisAlignment.center),
      phoneText: 'Telefone: (00) 00000-0000',
      phoneStyle: PrintStyle(
          fontSize: 10, isBold: false, alignment: CrossAxisAlignment.center),
      infoStyle: PrintStyle(
          fontSize: 10, isBold: false, alignment: CrossAxisAlignment.center),
      itemStyle: PrintStyle(
          fontSize: 10, isBold: false, alignment: CrossAxisAlignment.start),
      totalStyle: PrintStyle(
          fontSize: 14, isBold: true, alignment: CrossAxisAlignment.start),
      finalMessageText: 'Obrigado pela preferência!',
      finalMessageStyle: PrintStyle(
          fontSize: 10, isBold: false, alignment: CrossAxisAlignment.center),
    );
  }

  Map<String, dynamic> toJson() => {
        'logoPath': logoPath,
        'logoHeight': logoHeight,
        'logoAlignment': alignmentToString(logoAlignment), // Serialização
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

  factory ReceiptTemplateSettings.fromJson(Map<String, dynamic> json) =>
      ReceiptTemplateSettings(
        logoPath: json['logoPath'],
        logoHeight: (json['logoHeight'] as num? ?? 40.0).toDouble(),
        logoAlignment:
            alignmentFromString(json['logoAlignment'] as String? ?? 'center'), // Desserialização
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
        finalMessageText:
            json['finalMessageText'] ?? 'Obrigado pela preferência!',
        finalMessageStyle:
            PrintStyle.fromJson(json['finalMessageStyle'] ?? {}),
      );
}