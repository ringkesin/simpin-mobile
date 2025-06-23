// feature/berita/screens/semua_berita_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkba_mobile/model/berita.dart';
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/theme.dart';
import 'berita_detail.dart';

class SemuaBeritaScreen extends StatefulWidget {
  const SemuaBeritaScreen({super.key});

  @override
  State<SemuaBeritaScreen> createState() => _SemuaBeritaScreenState();
}

class _SemuaBeritaScreenState extends State<SemuaBeritaScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<BeritaItem> _beritaList = [];
  int _currentPage = 1;
  final int _perPage = 10; // Jumlah item per halaman
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchBerita(isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        _hasMore) {
      _fetchBerita();
    }
  }

  void _onSearchChanged(String query) {
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });
      _fetchBerita(isRefresh: true);
    }
  }

  Future<void> _fetchBerita({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _beritaList = [];
      _hasMore = true;
      setState(() => _isLoading = true);
    } else {
      setState(() => _isFetchingMore = true);
    }

    try {
      // DIUBAH: Panggil metode searchBerita yang baru
      final response = await _apiService.searchBerita(
        page: _currentPage,
        perpage: _perPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _beritaList.addAll(response.data!.content);
            // Logika _hasMore: jika jumlah item yang diterima < perpage, berarti halaman terakhir
            _hasMore = response.data!.content.length == _perPage;
            _currentPage++;
          });
        } else {
          setState(() => _hasMore = false);
        }
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _errorMessage = e.toString().replaceFirst("Exception: ", ""),
        );
    } finally {
      if (mounted)
        setState(() => {_isLoading = false, _isFetchingMore = false});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Berita'),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.primaryBackgroundLight,
      body: Column(
        children: [
          // BARU: Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari judul atau isi berita...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: _onSearchChanged,
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _beritaList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _beritaList.isEmpty) {
      return Center(child: Text('Gagal memuat berita: $_errorMessage'));
    }
    if (_beritaList.isEmpty) {
      return const Center(child: Text('Tidak ada berita ditemukan.'));
    }

    return RefreshIndicator(
      onRefresh: () => _fetchBerita(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _beritaList.length + (_isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _beritaList.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final berita = _beritaList[index];
          return _buildBeritaListItem(berita);
        },
      ),
    );
  }

  Widget _buildBeritaListItem(BeritaItem berita) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => BeritaDetailScreen(
                    beritaId: berita.id!,
                    beritaTitle: berita.title,
                  ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (berita.thumbnailPath != null &&
                berita.thumbnailPath!.isNotEmpty)
              Image.network(
                berita.thumbnailPath!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (ctx, err, stack) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, color: Colors.grey[400]),
                    ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat(
                      'dd MMMM yyyy',
                      'id_ID',
                    ).format(DateTime.parse(berita.validFrom)),
                    style: AppTheme.textThemeLight.labelSmall?.copyWith(
                      color: AppColors.secondaryTextLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    berita.title,
                    style: AppTheme.textThemeLight.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
