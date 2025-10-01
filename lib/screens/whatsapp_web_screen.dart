import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WhatsAppWebScreen extends StatefulWidget {
  const WhatsAppWebScreen({super.key});

  @override
  State<WhatsAppWebScreen> createState() => _WhatsAppWebScreenState();
}

class _WhatsAppWebScreenState extends State<WhatsAppWebScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  double progress = 0;

  final InAppWebViewSettings settings = InAppWebViewSettings(
    userAgent:
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36",
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(
              url: WebUri("https://web.whatsapp.com/"),
            ),
            initialSettings: settings,
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                this.progress = progress / 100;
              });
            },
          ),
          if (progress < 1.0)
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor),
            ),
        ],
      ),
    );
  }
}