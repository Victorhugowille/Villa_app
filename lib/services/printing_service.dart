// lib/services/printing_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/models/print_style_settings.dart';

class PrintingService {
  Future<void> printKitchenOrder({
    required List<app_data.CartItem> items,
    required String tableNumber,
    required int orderId,
    required Printer printer,
    required String paperSize,
    required PrintTemplateSettings templateSettings,
  }) async {
    final pdfBytes = await _generateKitchenOrderPdfBytes(
        items, tableNumber, orderId, paperSize, templateSettings);

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
    required String companyName,
  }) async {
    final pdfBytes = await _generateReceiptPdfBytes(
        orders, tableNumber, totalAmount, settings, companyName);
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes);
  }

  Future<Uint8List> getKitchenOrderPdfBytes({
    required List<app_data.CartItem> items,
    required String tableNumber,
    required int orderId,
    required String paperSize,
    required PrintTemplateSettings templateSettings,
  }) async {
    return _generateKitchenOrderPdfBytes(
        items, tableNumber, orderId, paperSize, templateSettings);
  }

  Future<Uint8List> getReceiptPdfBytes({
    required List<app_data.Order> orders,
    required String tableNumber,
    required double totalAmount,
    required ReceiptTemplateSettings settings,
    required String companyName,
  }) async {
    return _generateReceiptPdfBytes(
        orders, tableNumber, totalAmount, settings, companyName);
  }

  pw.Alignment _getAlignment(pw.CrossAxisAlignment crossAxisAlignment) {
    switch (crossAxisAlignment) {
      case pw.CrossAxisAlignment.start:
        return pw.Alignment.centerLeft;
      case pw.CrossAxisAlignment.center:
        return pw.Alignment.center;
      case pw.CrossAxisAlignment.end:
        return pw.Alignment.centerRight;
      default:
        return pw.Alignment.centerLeft;
    }
  }

  Future<pw.Widget> _getLogo(String? logoPath, double logoHeight) async {
    if (logoPath != null && logoPath.isNotEmpty) {
      final file = File(logoPath);
      if (await file.exists()) {
        final imageBytes = await file.readAsBytes();
        return pw.Image(pw.MemoryImage(imageBytes), height: logoHeight);
      }
    }
    final ByteData assetData =
        await rootBundle.load('assets/images/logoVilla.jpg');
    final Uint8List assetBytes = assetData.buffer.asUint8List();
    return pw.Image(pw.MemoryImage(assetBytes), height: logoHeight);
  }

  Future<Uint8List> _generateKitchenOrderPdfBytes(
    List<app_data.CartItem> items,
    String tableNumber,
    int orderId,
    String paperSize,
    PrintTemplateSettings settings,
  ) async {
    final pdf = pw.Document();
    final logoWidget = await _getLogo(settings.logoPath, settings.logoHeight);

    final pageFormat = paperSize == '80'
        ? const PdfPageFormat(
            80 * PdfPageFormat.mm,
            double.infinity,
            marginLeft: 2 * PdfPageFormat.mm,
            marginRight: 2 * PdfPageFormat.mm,
            marginTop: 2 * PdfPageFormat.mm,
            marginBottom: 2 * PdfPageFormat.mm,
          )
        : const PdfPageFormat(
            57 * PdfPageFormat.mm,
            double.infinity,
            marginLeft: 1.5 * PdfPageFormat.mm,
            marginRight: 1.5 * PdfPageFormat.mm,
            marginTop: 1.5 * PdfPageFormat.mm,
            marginBottom: 1.5 * PdfPageFormat.mm,
          );

    pw.TextStyle _getTextStyle(PrintStyle style) {
      return pw.TextStyle(
        fontWeight: style.isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        fontSize: style.fontSize,
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        orientation: pw.PageOrientation.portrait,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Container(
                width: double.infinity,
                alignment: pw.Alignment.center,
                child: logoWidget,
              ),
              pw.SizedBox(height: 5),
              pw.Center(child: pw.Text('----------------------------------')),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                alignment: _getAlignment(settings.tableStyle.alignment),
                child: pw.Text('MESA $tableNumber',
                    style: _getTextStyle(settings.tableStyle)),
              ),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                alignment: _getAlignment(settings.orderInfoStyle.alignment),
                child: pw.Text(
                  'Pedido #$orderId - ${DateFormat('HH:mm').format(DateTime.now())}',
                  style: _getTextStyle(settings.orderInfoStyle),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(child: pw.Text('----------------------------------')),
              pw.SizedBox(height: 5),
              for (final item in items)
                pw.Container(
                  width: double.infinity,
                  alignment: _getAlignment(settings.itemStyle.alignment),
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(
                    '(${item.quantity}) ${item.product.name}',
                    style: _getTextStyle(settings.itemStyle),
                  ),
                ),
              if (settings.footerText.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10),
                  child: pw.Container(
                    width: double.infinity,
                    alignment: _getAlignment(settings.footerStyle.alignment),
                    child: pw.Text(settings.footerText,
                        style: _getTextStyle(settings.footerStyle)),
                  ),
                ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> _generateReceiptPdfBytes(
      List<app_data.Order> orders,
      String tableNumber,
      double totalAmount,
      ReceiptTemplateSettings settings,
      String companyName) async {
    final pdf = pw.Document();
    final logoWidget = await _getLogo(settings.logoPath, settings.logoHeight);

    pw.TextStyle _getTextStyle(PrintStyle style) {
      return pw.TextStyle(
        fontWeight: style.isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        fontSize: style.fontSize,
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          57 * PdfPageFormat.mm,
          double.infinity,
          marginLeft: 2 * PdfPageFormat.mm,
          marginRight: 2 * PdfPageFormat.mm,
          marginTop: 2 * PdfPageFormat.mm,
          marginBottom: 2 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                alignment: pw.Alignment.center,
                child: logoWidget,
              ),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                alignment: pw.Alignment.center,
                child: pw.Text(companyName,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              if (settings.subtitleText.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  alignment: _getAlignment(settings.subtitleStyle.alignment),
                  child: pw.Text(settings.subtitleText,
                      style: _getTextStyle(settings.subtitleStyle)),
                ),
              if (settings.addressText.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  alignment: _getAlignment(settings.addressStyle.alignment),
                  child: pw.Text(settings.addressText,
                      style: _getTextStyle(settings.addressStyle)),
                ),
              if (settings.phoneText.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  alignment: _getAlignment(settings.phoneStyle.alignment),
                  child: pw.Text(settings.phoneText,
                      style: _getTextStyle(settings.phoneStyle)),
                ),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                alignment: _getAlignment(settings.infoStyle.alignment),
                child: pw.Text('Conferência - Mesa $tableNumber',
                    style: _getTextStyle(settings.infoStyle)),
              ),
              pw.Container(
                width: double.infinity,
                alignment: _getAlignment(settings.infoStyle.alignment),
                child: pw.Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                    style: _getTextStyle(settings.infoStyle)),
              ),
              pw.Divider(height: 12),
              pw.Column(
                children: orders.expand((order) => order.items).map((item) {
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${item.quantity}x ${item.product.name}',
                          style: _getTextStyle(settings.itemStyle),
                        ),
                      ),
                      pw.Text(
                        'R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                        style: _getTextStyle(settings.itemStyle),
                      ),
                    ],
                  );
                }).toList(),
              ),
              pw.Divider(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:',
                      style: _getTextStyle(settings.totalStyle)),
                  pw.Text('R\$ ${totalAmount.toStringAsFixed(2)}',
                      style: _getTextStyle(settings.totalStyle)),
                ],
              ),
              pw.SizedBox(height: 20),
              if (settings.finalMessageText.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  alignment:
                      _getAlignment(settings.finalMessageStyle.alignment),
                  child: pw.Text(settings.finalMessageText,
                      style: _getTextStyle(settings.finalMessageStyle)),
                ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }
}