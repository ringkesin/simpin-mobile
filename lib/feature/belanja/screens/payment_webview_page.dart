import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kkba_mobile/theme.dart';

class PaymentWebViewPage extends StatefulWidget {
  final Uri url;
  const PaymentWebViewPage({super.key, required this.url});

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pembayaran',
          style: GoogleFonts.lexendDeca(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTextLight,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.primaryTextLight,
      ),
      body: Column(
        children: [
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              color: AppColors.primaryLight,
              minHeight: 2,
            ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url.toString())),
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100.0);
              },
            ),
          ),
        ],
      ),
    );
  }
}
