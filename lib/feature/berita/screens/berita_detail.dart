// feature/berita/screens/berita_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:kkba_mobile/model/berita.dart';
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/theme.dart';

// Impor halaman viewer yang baru dibuat
import 'fullscreen_viewer.dart';

class BeritaDetailScreen extends StatefulWidget {
  final String beritaId;
  final String beritaTitle;

  const BeritaDetailScreen({
    super.key,
    required this.beritaId,
    required this.beritaTitle,
  });

  @override
  State<BeritaDetailScreen> createState() => _BeritaDetailScreenState();
}

class _BeritaDetailScreenState extends State<BeritaDetailScreen> {
  final ApiService _apiService = ApiService();
  BeritaItem? _beritaDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final response = await _apiService.getBeritaById(widget.beritaId);
      if (mounted) {
        if (response.success && response.data?.content != null) {
          setState(() => _beritaDetail = response.data!.content);
        } else {
          setState(
            () => _errorMessage = response.message ?? 'Gagal memuat detail.',
          );
        }
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _errorMessage = e.toString().replaceFirst("Exception: ", ""),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- PERUBAHAN: AppBar sekarang standar, tidak lagi SliverAppBar ---
      appBar: AppBar(
        title: Text(widget.beritaTitle),
        backgroundColor:
            AppColors.primaryLight, // Sesuaikan dengan warna tema Anda
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Error: $_errorMessage"),
                ),
              )
              : _buildDetailContent(),
    );
  }

  // --- PERUBAHAN: Struktur konten diubah menjadi SingleChildScrollView ---
  Widget _buildDetailContent() {
    if (_beritaDetail == null) {
      return const Center(child: Text("Data berita tidak ditemukan."));
    }
    final berita = _beritaDetail!;
    final heroTag = 'berita-image-${berita.id}'; // Tag unik untuk animasi Hero

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- BAGIAN GAMBAR UTAMA (HERO IMAGE) ---
          if (berita.thumbnailPath != null && berita.thumbnailPath!.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => FullScreenImageViewer(
                          imageUrl: berita.thumbnailPath!,
                          heroTag: heroTag,
                        ),
                  ),
                );
              },
              child: Hero(
                tag: heroTag,
                child: Image.network(
                  berita.thumbnailPath!,
                  width: double.infinity,
                  fit: BoxFit.fitWidth, // Memastikan lebar gambar penuh
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100),
                ),
              ),
            ),

          // --- BAGIAN KONTEN TEKS ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  berita.title,
                  style: AppTheme.textThemeLight.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Dipublikasikan pada ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.parse(berita.validFrom))}",
                  style: AppTheme.textThemeLight.bodySmall?.copyWith(
                    color: AppColors.secondaryTextLight,
                  ),
                ),
                const Divider(height: 32),
                Html(
                  data: berita.text,
                  style: {
                    "body": Style(
                      fontSize: FontSize(16.0),
                      lineHeight: const LineHeight(1.5),
                    ),
                    "p": Style(margin: Margins.zero),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
