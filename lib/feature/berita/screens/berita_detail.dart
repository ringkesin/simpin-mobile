// feature/berita/screens/berita_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:kkba_mobile/model/berita.dart';
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/theme.dart';

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
        // DIUBAH: Akses data melalui response.data.content sesuai model baru
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

  Widget _buildDetailContent() {
    if (_beritaDetail == null) {
      return const Center(child: Text("Data berita tidak ditemukan."));
    }
    final berita = _beritaDetail!;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250.0,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              widget.beritaTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
              ),
            ),
            background:
                berita.thumbnailPath != null && berita.thumbnailPath!.isNotEmpty
                    ? Image.network(
                      berita.thumbnailPath!,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.3),
                      colorBlendMode: BlendMode.darken,
                    )
                    : Container(color: Colors.grey),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // DIUBAH: Menggunakan berita.title
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
                  // DIUBAH: Menggunakan berita.text untuk konten HTML
                  data: berita.text,
                  style: {
                    "body": Style(
                      fontSize: FontSize(16.0),
                      lineHeight: const LineHeight(1.5),
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
