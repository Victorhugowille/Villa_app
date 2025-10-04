import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/models/print_style_settings.dart';

class PrintingService {
  pw.CrossAxisAlignment _flutterToPdfAlignment(CrossAxisAlignment alignment) {
    switch (alignment) {
      case CrossAxisAlignment.center:
        return pw.CrossAxisAlignment.center;
      case CrossAxisAlignment.end:
        return pw.CrossAxisAlignment.end;
      case CrossAxisAlignment.start:
      default:
        return pw.CrossAxisAlignment.start;
    }
  }

  pw.Alignment _flutterToPdfLogoAlignment(CrossAxisAlignment alignment) {
    switch (alignment) {
      case CrossAxisAlignment.center:
        return pw.Alignment.center;
      case CrossAxisAlignment.end:
        return pw.Alignment.centerRight;
      case CrossAxisAlignment.start:
      default:
        return pw.Alignment.centerLeft;
    }
  }

  Alignment _flutterToWidgetLogoAlignment(CrossAxisAlignment alignment) {
    switch (alignment) {
      case CrossAxisAlignment.center:
        return Alignment.center;
      case CrossAxisAlignment.end:
        return Alignment.centerRight;
      case CrossAxisAlignment.start:
      default:
        return Alignment.centerLeft;
    }
  }

  TextAlign _flutterToTextAlign(CrossAxisAlignment alignment) {
    switch (alignment) {
      case CrossAxisAlignment.center:
        return TextAlign.center;
      case CrossAxisAlignment.end:
        return TextAlign.right;
      case CrossAxisAlignment.start:
      default:
        return TextAlign.left;
    }
  }

  pw.TextAlign _pdfTextAlign(CrossAxisAlignment alignment) {
    switch (alignment) {
      case CrossAxisAlignment.center:
        return pw.TextAlign.center;
      case CrossAxisAlignment.end:
        return pw.TextAlign.right;
      case CrossAxisAlignment.start:
      default:
        return pw.TextAlign.left;
    }
  }

  Future<void> printKitchenOrder({
    required List<app_data.CartItem> items,
    required String tableNumber,
    required String orderId,
    required Printer printer,
    required String paperSize,
    required KitchenTemplateSettings templateSettings,
  }) async {
    final pdfBytes = await getKitchenOrderPdfBytes(
        items: items,
        tableNumber: tableNumber,
        orderId: orderId,
        paperSize: paperSize,
        templateSettings: templateSettings);

    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (format) async => pdfBytes,
    );
  }

  Future<void> printReceiptPdf({
    required List<app_data.Order> orders,
    required String tableNumber,
    required double totalAmount,
    required ReceiptTemplateSettings settings,
  }) async {
    final pdfBytes = await getReceiptPdfBytes(
        orders: orders,
        tableNumber: tableNumber,
        totalAmount: totalAmount,
        settings: settings);
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes);
  }

  Future<Uint8List> getKitchenOrderPdfBytes({
    required List<app_data.CartItem> items,
    required String tableNumber,
    required String orderId,
    required String paperSize,
    required KitchenTemplateSettings templateSettings,
  }) async {
    final doc = pw.Document();
    final robotoRegular = await PdfGoogleFonts.robotoRegular();
    final robotoBold = await PdfGoogleFonts.robotoBold();

    pw.Widget? logoWidget;
    if (templateSettings.logoPath != null &&
        templateSettings.logoPath!.isNotEmpty) {
      final file = File(templateSettings.logoPath!);
      if (await file.exists()) {
        logoWidget = pw.Image(pw.MemoryImage(await file.readAsBytes()),
            height: templateSettings.logoHeight);
      }
    }

    pw.TextStyle getTextStyle(PrintStyle style, {bool isAdicional = false}) {
      return pw.TextStyle(
        font: style.isBold ? robotoBold : robotoRegular,
        fontSize: isAdicional ? style.fontSize - 1 : style.fontSize, // Fonte menor para adicional
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat:
            paperSize == '80' ? PdfPageFormat.roll80 : PdfPageFormat.roll57,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment:
                _flutterToPdfAlignment(templateSettings.itemStyle.alignment),
            children: [
              if (logoWidget != null)
                pw.Align(
                  alignment:
                      _flutterToPdfLogoAlignment(templateSettings.logoAlignment),
                  child: logoWidget,
                ),
              pw.SizedBox(height: 5),
              pw.SizedBox(
                width: double.infinity,
                child: pw.Text(
                  'MESA $tableNumber',
                  style: getTextStyle(templateSettings.tableStyle),
                  textAlign:
                      _pdfTextAlign(templateSettings.tableStyle.alignment),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.SizedBox(
                width: double.infinity,
                child: pw.Text(
                  'Pedido #${orderId.length > 8 ? orderId.substring(0, 8) : orderId} - ${DateFormat('HH:mm').format(DateTime.now())}',
                  style: getTextStyle(templateSettings.orderInfoStyle),
                  textAlign:
                      _pdfTextAlign(templateSettings.orderInfoStyle.alignment),
                ),
              ),
              pw.Divider(color: PdfColors.black),
              for (final item in items)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Column(
                    crossAxisAlignment: _flutterToPdfAlignment(templateSettings.itemStyle.alignment),
                    children: [
                      pw.Text(
                        '(${item.quantity}) ${item.product.name}',
                        style: getTextStyle(templateSettings.itemStyle),
                        textAlign:
                            _pdfTextAlign(templateSettings.itemStyle.alignment),
                      ),
                      if(item.selectedAdicionais.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 15.0),
                          child: pw.Column(
                             crossAxisAlignment: _flutterToPdfAlignment(templateSettings.itemStyle.alignment),
                            children: item.selectedAdicionais.map((itemAd) {
                              final ad = itemAd.adicional;
                              return pw.Text(
                                "+ ${itemAd.quantity}x ${ad.name}",
                                style: getTextStyle(templateSettings.itemStyle, isAdicional: true),
                                textAlign: _pdfTextAlign(templateSettings.itemStyle.alignment),
                              );
                            }).toList(),
                          )
                        )
                    ]
                  ),
                ),
              if (templateSettings.footerText.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10),
                  child: pw.SizedBox(
                    width: double.infinity,
                    child: pw.Text(
                      templateSettings.footerText,
                      style: getTextStyle(templateSettings.footerStyle),
                      textAlign:
                          _pdfTextAlign(templateSettings.footerStyle.alignment),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  Future<Uint8List> getReceiptPdfBytes({
    required List<app_data.Order> orders,
    required String tableNumber,
    required double totalAmount,
    required ReceiptTemplateSettings settings,
  }) async {
    final doc = pw.Document();
    final robotoRegular = await PdfGoogleFonts.robotoRegular();
    final robotoBold = await PdfGoogleFonts.robotoBold();

    pw.Widget? logoWidget;
    if (settings.logoPath != null && settings.logoPath!.isNotEmpty) {
      final file = File(settings.logoPath!);
      if (await file.exists()) {
        logoWidget = pw.Image(pw.MemoryImage(await file.readAsBytes()),
            height: settings.logoHeight);
      }
    }

    pw.TextStyle getTextStyle(PrintStyle style) {
      return pw.TextStyle(
        font: style.isBold ? robotoBold : robotoRegular,
        fontSize: style.fontSize,
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoWidget != null)
                pw.Align(
                  alignment: _flutterToPdfLogoAlignment(settings.logoAlignment),
                  child: logoWidget,
                ),
              pw.SizedBox(height: 5),
              if (settings.subtitleText.isNotEmpty)
                pw.SizedBox(
                  width: double.infinity,
                  child: pw.Text(
                    settings.subtitleText,
                    style: getTextStyle(settings.subtitleStyle),
                    textAlign: _pdfTextAlign(settings.subtitleStyle.alignment),
                  ),
                ),
              if (settings.addressText.isNotEmpty)
                pw.SizedBox(
                  width: double.infinity,
                  child: pw.Text(
                    settings.addressText,
                    style: getTextStyle(settings.addressStyle),
                    textAlign: _pdfTextAlign(settings.addressStyle.alignment),
                  ),
                ),
              if (settings.phoneText.isNotEmpty)
                pw.SizedBox(
                  width: double.infinity,
                  child: pw.Text(
                    settings.phoneText,
                    style: getTextStyle(settings.phoneStyle),
                    textAlign: _pdfTextAlign(settings.phoneStyle.alignment),
                  ),
                ),
              pw.SizedBox(
                width: double.infinity,
                child: pw.Text(
                  'Conferência - Mesa $tableNumber',
                  style: getTextStyle(settings.infoStyle),
                  textAlign: _pdfTextAlign(settings.infoStyle.alignment),
                ),
              ),
              pw.Divider(color: PdfColors.black, height: 12),
              for (final item in orders.expand((order) => order.items))
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${item.quantity}x ${item.product.name}',
                              style: getTextStyle(settings.itemStyle),
                            ),
                          ),
                          pw.Text(
                            'R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                            style: getTextStyle(settings.itemStyle),
                          ),
                        ],
                      ),
                      if (item.selectedAdicionais.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 10.0),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: item.selectedAdicionais.map((itemAd) {
                              final ad = itemAd.adicional;
                              return pw.Text(
                                "+ ${itemAd.quantity}x ${ad.name} (+ R\$ ${(ad.price * itemAd.quantity).toStringAsFixed(2)})",
                                style: getTextStyle(settings.itemStyle).copyWith(fontSize: settings.itemStyle.fontSize - 1),
                              );
                            }).toList(),
                          ),
                        )
                    ]
                  ),
              pw.Divider(color: PdfColors.black, height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:', style: getTextStyle(settings.totalStyle)),
                  pw.Text('R\$ ${totalAmount.toStringAsFixed(2)}',
                      style: getTextStyle(settings.totalStyle)),
                ],
              ),
              if (settings.finalMessageText.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8.0),
                  child: pw.SizedBox(
                    width: double.infinity,
                    child: pw.Text(
                      settings.finalMessageText,
                      style: getTextStyle(settings.finalMessageStyle),
                      textAlign:
                          _pdfTextAlign(settings.finalMessageStyle.alignment),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  Widget buildKitchenOrderWidget({
    required List<app_data.CartItem> items,
    required String tableNumber,
    required String orderId,
    required KitchenTemplateSettings templateSettings,
  }) {
    TextStyle getTextStyle(PrintStyle style, {bool isAdicional = false}) {
      return TextStyle(
        fontSize: isAdicional ? style.fontSize - 1 : style.fontSize,
        fontWeight: style.isBold ? FontWeight.bold : FontWeight.normal,
        color: Colors.black,
        fontFamily: 'Roboto',
      );
    }

    bool hasLogo = templateSettings.logoPath != null &&
        templateSettings.logoPath!.isNotEmpty &&
        File(templateSettings.logoPath!).existsSync();

    return Column(
      crossAxisAlignment: templateSettings.itemStyle.alignment,
      children: [
        if (hasLogo)
          Padding(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: Align(
              alignment:
                  _flutterToWidgetLogoAlignment(templateSettings.logoAlignment),
              child: Image.file(File(templateSettings.logoPath!),
                  key: UniqueKey(), height: templateSettings.logoHeight),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: Text(
            'MESA $tableNumber',
            style: getTextStyle(templateSettings.tableStyle),
            textAlign:
                _flutterToTextAlign(templateSettings.tableStyle.alignment),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: double.infinity,
          child: Text(
            'Pedido #${orderId.length > 8 ? orderId.substring(0, 8) : orderId} - ${DateFormat('HH:mm').format(DateTime.now())}',
            style: getTextStyle(templateSettings.orderInfoStyle),
            textAlign:
                _flutterToTextAlign(templateSettings.orderInfoStyle.alignment),
          ),
        ),
        const Divider(color: Colors.black),
        for (final item in items)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: templateSettings.itemStyle.alignment,
                children: [
                  Text(
                    '(${item.quantity}) ${item.product.name}',
                    style: getTextStyle(templateSettings.itemStyle),
                    textAlign:
                        _flutterToTextAlign(templateSettings.itemStyle.alignment),
                  ),
                   if(item.selectedAdicionais.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: Column(
                        crossAxisAlignment: templateSettings.itemStyle.alignment,
                        children: item.selectedAdicionais.map((itemAd) {
                          final ad = itemAd.adicional;
                          return Text(
                            "+ ${itemAd.quantity}x ${ad.name}",
                             style: getTextStyle(templateSettings.itemStyle, isAdicional: true),
                             textAlign: _flutterToTextAlign(templateSettings.itemStyle.alignment),
                          );
                        }).toList(),
                      )
                    )
                ],
              ),
            ),
        if (templateSettings.footerText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                templateSettings.footerText,
                style: getTextStyle(templateSettings.footerStyle),
                textAlign:
                    _flutterToTextAlign(templateSettings.footerStyle.alignment),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildReceiptWidget({
    required List<app_data.Order> orders,
    required String tableNumber,
    required double totalAmount,
    required ReceiptTemplateSettings settings,
  }) {
    TextStyle getTextStyle(PrintStyle style) {
      return TextStyle(
        fontSize: style.fontSize,
        fontWeight: style.isBold ? FontWeight.bold : FontWeight.normal,
        color: Colors.black,
        fontFamily: 'Roboto',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (settings.logoPath != null &&
            settings.logoPath!.isNotEmpty &&
            File(settings.logoPath!).existsSync())
          Padding(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: Align(
              alignment: _flutterToWidgetLogoAlignment(settings.logoAlignment),
              child: Image.file(File(settings.logoPath!),
                  key: UniqueKey(), height: settings.logoHeight),
            ),
          ),
        if (settings.subtitleText.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: Text(
              settings.subtitleText,
              style: getTextStyle(settings.subtitleStyle),
              textAlign: _flutterToTextAlign(settings.subtitleStyle.alignment),
            ),
          ),
        if (settings.addressText.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: Text(
              settings.addressText,
              style: getTextStyle(settings.addressStyle),
              textAlign: _flutterToTextAlign(settings.addressStyle.alignment),
            ),
          ),
        if (settings.phoneText.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: Text(
              settings.phoneText,
              style: getTextStyle(settings.phoneStyle),
              textAlign: _flutterToTextAlign(settings.phoneStyle.alignment),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: Text(
            'Conferência - Mesa $tableNumber',
            style: getTextStyle(settings.infoStyle),
            textAlign: _flutterToTextAlign(settings.infoStyle.alignment),
          ),
        ),
        const Divider(color: Colors.black, height: 12),
        for (final item in orders.expand((order) => order.items))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.product.name}',
                        style: getTextStyle(settings.itemStyle),
                      ),
                    ),
                    Text(
                      'R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                      style: getTextStyle(settings.itemStyle),
                    ),
                  ],
                ),
                 if (item.selectedAdicionais.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: item.selectedAdicionais.map((itemAd) {
                          final ad = itemAd.adicional;
                          return Text(
                            "+ ${itemAd.quantity}x ${ad.name} (+ R\$ ${(ad.price * itemAd.quantity).toStringAsFixed(2)})",
                             style: TextStyle(fontSize: settings.itemStyle.fontSize - 1, color: Colors.black87),
                          );
                        }).toList(),
                      ),
                    )
              ],
            ),
          ),
        const Divider(color: Colors.black, height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total:', style: getTextStyle(settings.totalStyle)),
            Text('R\$ ${totalAmount.toStringAsFixed(2)}',
                style: getTextStyle(settings.totalStyle)),
          ],
        ),
        if (settings.finalMessageText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                settings.finalMessageText,
                style: getTextStyle(settings.finalMessageStyle),
                textAlign:
                    _flutterToTextAlign(settings.finalMessageStyle.alignment),
              ),
            ),
          ),
      ],
    );
  }
}