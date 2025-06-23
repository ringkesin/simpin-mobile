// feature/profile/screens/document_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../service/api_service.dart'; // Import ApiService
import '../../../theme.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const DocumentViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  final ApiService _apiService = ApiService();

  // DIUBAH: State untuk menangani loading dan URL final
  bool _isResolvingUrl = true; // Status loading untuk pengecekan URL
  WebUri? _finalUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _resolveUrl(); // Panggil fungsi pengecekan URL
  }

  // BARU: Fungsi untuk memeriksa tipe konten dan menentukan URL yang akan dimuat
  Future<void> _resolveUrl() async {
    try {
      // Panggil metode baru dari ApiService
      final contentType = await _apiService.checkUrlContentType(widget.url);

      if (contentType != null && contentType.contains('application/pdf')) {
        // Jika server mengkonfirmasi ini adalah PDF
        final encodedUrl = Uri.encodeComponent(widget.url);
        final googleDocsUrl =
            'https://docs.google.com/gview?embedded=true&url=$encodedUrl';
        setState(() {
          _finalUrl = WebUri(googleDocsUrl);
        });
      } else {
        // Jika bukan PDF atau pengecekan gagal, muat URL asli
        setState(() {
          _finalUrl = WebUri(widget.url);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Gagal memproses URL: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isResolvingUrl = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      // DIUBAH: Tampilan body sekarang kondisional
      body:
          _isResolvingUrl
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryLight),
              )
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_errorMessage!),
                ),
              )
              : _finalUrl == null
              ? const Center(child: Text("URL tidak valid."))
              : InAppWebView(
                initialUrlRequest: URLRequest(url: _finalUrl!),
                // Opsi lain bisa ditambahkan di sini jika perlu
              ),
    );
  }
}
