import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final String paymentUrl;

  const PaymentScreen({super.key, required this.paymentUrl});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => isLoading = true);
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (url) {
            setState(() => isLoading = false);
            debugPrint('Page finished loading: $url');
          },
          onNavigationRequest: (request) {
            final url = request.url;
            debugPrint('Navigating to: $url');

            // Handle various Midtrans callback URLs
            if (url.contains('midtrans-return.flutter-app') ||
                url.contains('success') ||
                url.contains('finish') ||
                url.contains('payment-success')) {
              Navigator.pop(context, 'paid');
              return NavigationDecision.prevent;
            }

            // Handle failure scenarios
            if (url.contains('failure') ||
                url.contains('error') ||
                url.contains('cancel')) {
              Navigator.pop(context, 'failed');
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint('Web error: ${error.description}');
            setState(() => isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: const Color(0xFFF8F3E5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3E2723)),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
