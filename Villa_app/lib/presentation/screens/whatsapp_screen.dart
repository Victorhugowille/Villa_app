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
  bool hasError = false;
  String? errorMessage;

  final InAppWebViewSettings settings = InAppWebViewSettings(
    userAgent:
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    cacheMode: CacheMode.LOAD_DEFAULT,
    verticalScrollBarEnabled: true,
    horizontalScrollBarEnabled: true,
  );

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 Inicializando WhatsApp Screen...');
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      // Não é necessário limpar cache para WebView
      debugPrint('✅ WebView pronto para carregar');
    } catch (e) {
      debugPrint('❌ Erro na inicialização: $e');
    }
  }

  void _reload() {
    try {
      webViewController?.reload();
      setState(() {
        hasError = false;
        errorMessage = null;
      });
    } catch (e) {
      debugPrint('❌ Erro ao recarregar: $e');
    }
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (webViewController != null) {
          final canGoBack = await webViewController!.canGoBack();
          if (canGoBack) {
            await webViewController!.goBack();
            return false;
          }
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            if (!hasError)
              InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(
                  url: WebUri("https://web.whatsapp.com/"),
                ),
                initialSettings: settings,
                onWebViewCreated: (controller) {
                  setState(() {
                    webViewController = controller;
                    hasError = false;
                    errorMessage = null;
                  });
                  debugPrint('✅ WebView criado com sucesso');
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    this.progress = progress / 100;
                  });
                },
                onLoadStart: (controller, url) {
                  debugPrint('📍 Carregando: $url');
                  setState(() {
                    hasError = false;
                    errorMessage = null;
                    progress = 0;
                  });
                },
                onLoadStop: (controller, url) {
                  debugPrint('✅ Carregamento completo: $url');
                  setState(() {
                    progress = 1.0;
                  });
                },
                onLoadError: (controller, url, code, message) {
                  debugPrint('❌ Erro ao carregar ($code): $message');
                  setState(() {
                    hasError = true;
                    errorMessage = 'Erro: $message (Código: $code)';
                    progress = 1.0;
                  });
                },
                onLoadHttpError: (controller, url, statusCode, description) {
                  debugPrint('❌ Erro HTTP ($statusCode): $description');
                  if (statusCode != 200) {
                    setState(() {
                      hasError = true;
                      errorMessage = 'Erro HTTP: $statusCode';
                    });
                  }
                },
                onConsoleMessage: (controller, consoleMessage) {
                  debugPrint('📱 Console: ${consoleMessage.message}');
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final uri = navigationAction.request.url;
                  debugPrint('🔗 Navegando para: $uri');
                  return NavigationActionPolicy.ALLOW;
                },
                onReceivedError: (controller, request, error) {
                  debugPrint('❌ Erro recebido: ${error.description}');
                  setState(() {
                    hasError = true;
                    errorMessage = 'Erro: ${error.description}';
                  });
                },
                onReceivedHttpError: (controller, request, error) {
                  debugPrint('❌ Erro HTTP recebido');
                  if (error.statusCode != 200) {
                    setState(() {
                      hasError = true;
                      errorMessage = 'Erro HTTP ${error.statusCode}';
                    });
                  }
                },
              ),

            if (hasError)
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar WhatsApp',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          errorMessage ?? 'Ocorreu um erro desconhecido',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _goBack,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Voltar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (progress < 1.0 && !hasError)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    webViewController = null;
    super.dispose();
  }
}