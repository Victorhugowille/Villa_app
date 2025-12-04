// lib/models/print_style_settings.dart
import 'package:flutter/material.dart' show CrossAxisAlignment;

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
  // --- MUDANÇA: Simplificação dos estilos ---
  final PrintStyle headerStyle; // Unifica 'tableStyle' e o antigo 'headerStyle'
  final PrintStyle orderInfoStyle;
  final PrintStyle itemStyle;
  final PrintStyle observationStyle; // Para observações de itens E GERAIS
  final PrintStyle deliveryInfoStyle;
  final String footerText;
  final PrintStyle footerStyle;
  final String? logoPath;
  final double logoHeight;
  final CrossAxisAlignment logoAlignment;
  // Dados do estabelecimento (opcional - só aparecem se houver cliente)
  final String subtitleText;
  final PrintStyle subtitleStyle;
  final String addressText;
  final PrintStyle addressStyle;
  final String phoneText;
  final PrintStyle phoneStyle;

  KitchenTemplateSettings({
    required this.headerStyle,
    required this.orderInfoStyle,
    required this.itemStyle,
    required this.observationStyle,
    required this.deliveryInfoStyle,
    required this.footerText,
    required this.footerStyle,
    this.logoPath,
    this.logoHeight = 40.0,
    required this.logoAlignment,
    this.subtitleText = '',
    required this.subtitleStyle,
    this.addressText = '',
    required this.addressStyle,
    this.phoneText = '',
    required this.phoneStyle,
  });

  KitchenTemplateSettings copyWith({
    PrintStyle? headerStyle,
    PrintStyle? orderInfoStyle,
    PrintStyle? itemStyle,
    PrintStyle? observationStyle,
    PrintStyle? deliveryInfoStyle,
    String? footerText,
    PrintStyle? footerStyle,
    String? logoPath,
    double? logoHeight,
    CrossAxisAlignment? logoAlignment,
    String? subtitleText,
    PrintStyle? subtitleStyle,
    String? addressText,
    PrintStyle? addressStyle,
    String? phoneText,
    PrintStyle? phoneStyle,
  }) {
    return KitchenTemplateSettings(
      headerStyle: headerStyle ?? this.headerStyle,
      orderInfoStyle: orderInfoStyle ?? this.orderInfoStyle,
      itemStyle: itemStyle ?? this.itemStyle,
      observationStyle: observationStyle ?? this.observationStyle,
      deliveryInfoStyle: deliveryInfoStyle ?? this.deliveryInfoStyle,
      footerText: footerText ?? this.footerText,
      footerStyle: footerStyle ?? this.footerStyle,
      logoPath: logoPath ?? this.logoPath,
      logoHeight: logoHeight ?? this.logoHeight,
      logoAlignment: logoAlignment ?? this.logoAlignment,
      subtitleText: subtitleText ?? this.subtitleText,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      addressText: addressText ?? this.addressText,
      addressStyle: addressStyle ?? this.addressStyle,
      phoneText: phoneText ?? this.phoneText,
      phoneStyle: phoneStyle ?? this.phoneStyle,
    );
  }

  factory KitchenTemplateSettings.defaults() => KitchenTemplateSettings(
        headerStyle: PrintStyle(fontSize: 16, isBold: true, alignment: CrossAxisAlignment.center),
        orderInfoStyle: PrintStyle(fontSize: 10, isBold: false, alignment: CrossAxisAlignment.center),
        itemStyle: PrintStyle(fontSize: 10, isBold: true, alignment: CrossAxisAlignment.start),
        observationStyle: PrintStyle(fontSize: 9, isBold: false, alignment: CrossAxisAlignment.start),
        deliveryInfoStyle: PrintStyle(fontSize: 10, isBold: false, alignment: CrossAxisAlignment.start),
        footerText: 'Obrigado!',
        footerStyle: PrintStyle(fontSize: 10, isBold: false, alignment: CrossAxisAlignment.center),
        logoPath: null,
        logoHeight: 40.0,
        logoAlignment: CrossAxisAlignment.center,
        subtitleText: '',
        subtitleStyle: PrintStyle(fontSize: 10, isBold: false, alignment: CrossAxisAlignment.center),
        addressText: '',
        addressStyle: PrintStyle(fontSize: 9, isBold: false, alignment: CrossAxisAlignment.center),
        phoneText: '',
        phoneStyle: PrintStyle(fontSize: 9, isBold: false, alignment: CrossAxisAlignment.center),
      );

  factory KitchenTemplateSettings.fromJson(Map<String, dynamic> json) {
    // Lógica para compatibilidade com versões antigas das configurações salvas
    final oldTableStyle = json['tableStyle'] != null ? PrintStyle.fromJson(json['tableStyle']) : null;
    final newHeaderStyle = json['headerStyle'] != null ? PrintStyle.fromJson(json['headerStyle']) : null;
    
    return KitchenTemplateSettings(
      headerStyle: newHeaderStyle ?? oldTableStyle ?? PrintStyle.fromJson(json['headerStyle'] ?? {}),
      orderInfoStyle: PrintStyle.fromJson(json['orderInfoStyle'] ?? {}),
      itemStyle: PrintStyle.fromJson(json['itemStyle'] ?? {}),
      observationStyle: PrintStyle.fromJson(json['observationStyle'] ?? {}),
      deliveryInfoStyle: PrintStyle.fromJson(json['deliveryInfoStyle'] ?? {}),
      footerText: json['footerText'] ?? 'Obrigado!',
      footerStyle: PrintStyle.fromJson(json['footerStyle'] ?? {}),
      logoPath: json['logoPath'],
      logoHeight: (json['logoHeight'] as num? ?? 40.0).toDouble(),
      logoAlignment: alignmentFromString(json['logoAlignment'] as String? ?? 'center'),
      subtitleText: json['subtitleText'] ?? '',
      subtitleStyle: PrintStyle.fromJson(json['subtitleStyle'] ?? {}),
      addressText: json['addressText'] ?? '',
      addressStyle: PrintStyle.fromJson(json['addressStyle'] ?? {}),
      phoneText: json['phoneText'] ?? '',
      phoneStyle: PrintStyle.fromJson(json['phoneStyle'] ?? {}),
    );
  }


  Map<String, dynamic> toJson() => {
        'headerStyle': headerStyle.toJson(),
        'orderInfoStyle': orderInfoStyle.toJson(),
        'itemStyle': itemStyle.toJson(),
        'observationStyle': observationStyle.toJson(),
        'deliveryInfoStyle': deliveryInfoStyle.toJson(),
        'footerText': footerText,
        'footerStyle': footerStyle.toJson(),
        'logoPath': logoPath,
        'logoHeight': logoHeight,
        'logoAlignment': alignmentToString(logoAlignment),
        'subtitleText': subtitleText,
        'subtitleStyle': subtitleStyle.toJson(),
        'addressText': addressText,
        'addressStyle': addressStyle.toJson(),
        'phoneText': phoneText,
        'phoneStyle': phoneStyle.toJson(),
      };
}


class ReceiptTemplateSettings {
  final String? logoPath;
  final double logoHeight;
  final CrossAxisAlignment logoAlignment;
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
  final PrintStyle deliveryInfoStyle;

  ReceiptTemplateSettings({
    this.logoPath,
    this.logoHeight = 40.0,
    required this.logoAlignment,
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
    required this.deliveryInfoStyle,
  });

  ReceiptTemplateSettings copyWith({
    String? logoPath,
    double? logoHeight,
    CrossAxisAlignment? logoAlignment,
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
    PrintStyle? deliveryInfoStyle,
  }) {
    return ReceiptTemplateSettings(
      logoPath: logoPath ?? this.logoPath,
      logoHeight: logoHeight ?? this.logoHeight,
      logoAlignment: logoAlignment ?? this.logoAlignment,
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
      deliveryInfoStyle: deliveryInfoStyle ?? this.deliveryInfoStyle,
    );
  }

  factory ReceiptTemplateSettings.defaults() {
    return ReceiptTemplateSettings(
      logoPath: null,
      logoHeight: 40.0,
      logoAlignment: CrossAxisAlignment.center,
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
      deliveryInfoStyle: PrintStyle(fontSize: 10, isBold: false, alignment: CrossAxisAlignment.start),
    );
  }

  Map<String, dynamic> toJson() => {
        'logoPath': logoPath,
        'logoHeight': logoHeight,
        'logoAlignment': alignmentToString(logoAlignment),
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
        'deliveryInfoStyle': deliveryInfoStyle.toJson(),
      };

  factory ReceiptTemplateSettings.fromJson(Map<String, dynamic> json) =>
      ReceiptTemplateSettings(
        logoPath: json['logoPath'],
        logoHeight: (json['logoHeight'] as num? ?? 40.0).toDouble(),
        logoAlignment:
            alignmentFromString(json['logoAlignment'] as String? ?? 'center'),
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
        deliveryInfoStyle: PrintStyle.fromJson(json['deliveryInfoStyle'] ?? {}),
      );
}