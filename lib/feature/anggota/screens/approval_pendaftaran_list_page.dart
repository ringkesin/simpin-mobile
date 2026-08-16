import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/feature/anggota/screens/approval_pendaftaran_detail_page.dart';
import 'package:kkba_mobile/model/anggota_registrasi_response.dart';
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/theme.dart';

enum _SortBy { namaAsc, namaDesc, tanggalMasukDesc, tanggalMasukAsc }

class ApprovalPendaftaranListPage extends StatefulWidget {
  const ApprovalPendaftaranListPage({super.key});

  @override
  State<ApprovalPendaftaranListPage> createState() =>
      _ApprovalPendaftaranListPageState();
}

class _ApprovalPendaftaranListPageState
    extends State<ApprovalPendaftaranListPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<AnggotaRegistrasiItem> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _page = 1;
  bool _hasMore = true;
  String _searchQuery = '';
  _SortBy _sortBy = _SortBy.tanggalMasukDesc;

  @override
  void initState() {
    super.initState();
    _fetchData(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchData();
    }
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == '-') return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  List<AnggotaRegistrasiItem> get _sortedItems {
    final list = List<AnggotaRegistrasiItem>.from(_items);
    switch (_sortBy) {
      case _SortBy.namaAsc:
        list.sort(
          (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()),
        );
        break;
      case _SortBy.namaDesc:
        list.sort(
          (a, b) => b.nama.toLowerCase().compareTo(a.nama.toLowerCase()),
        );
        break;
      case _SortBy.tanggalMasukDesc:
        list.sort((a, b) {
          final da = _parseDate(a.tanggalMasuk);
          final db = _parseDate(b.tanggalMasuk);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });
        break;
      case _SortBy.tanggalMasukAsc:
        list.sort((a, b) {
          final da = _parseDate(a.tanggalMasuk);
          final db = _parseDate(b.tanggalMasuk);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
        break;
    }
    return list;
  }

  String get _sortLabel {
    switch (_sortBy) {
      case _SortBy.namaAsc:
        return 'Nama A-Z';
      case _SortBy.namaDesc:
        return 'Nama Z-A';
      case _SortBy.tanggalMasukDesc:
        return 'Tanggal masuk terbaru';
      case _SortBy.tanggalMasukAsc:
        return 'Tanggal masuk terlama';
    }
  }

  Future<void> _fetchData({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _page = 1;
        _hasMore = true;
        _items.clear();
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await _apiService.getAnggotaRegistrasiBaru(
        page: _page,
        perPage: 15,
        search: _searchQuery,
      );

      if (!mounted) return;

      setState(() {
        _items.addAll(response.data);
        if (response.lastPage != null) {
          _hasMore = response.hasMore;
        } else {
          _hasMore = response.data.length >= 15;
        }
        if (_hasMore) _page += 1;
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onSearch() {
    _searchQuery = _searchController.text.trim();
    _fetchData(reset: true);
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.primaryBackgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final textTheme = AppTheme.textThemeLight;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryTextLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Urutkan berdasarkan',
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryTextLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ..._SortBy.values.map((option) {
                  final selected = _sortBy == option;
                  final label = switch (option) {
                    _SortBy.namaAsc => 'Nama A-Z',
                    _SortBy.namaDesc => 'Nama Z-A',
                    _SortBy.tanggalMasukDesc => 'Tanggal masuk terbaru',
                    _SortBy.tanggalMasukAsc => 'Tanggal masuk terlama',
                  };
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      label,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryTextLight,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    trailing:
                        selected
                            ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.primaryLight,
                            )
                            : null,
                    onTap: () {
                      setState(() => _sortBy = option);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == '-') return '-';
    try {
      final date = DateTime.parse(raw);
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return raw.split('T').first;
    }
  }

  Future<void> _openDetail(AnggotaRegistrasiItem item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ApprovalPendaftaranDetailPage(anggota: item),
      ),
    );
    if (changed == true && mounted) {
      _fetchData(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTheme.textThemeLight;

    return Scaffold(
      backgroundColor: AppColors.primaryBackgroundLight,
      appBar: AppBar(
        title: Text(
          'Approval Pendaftaran',
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.primaryTextLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryBackgroundLight,
        foregroundColor: AppColors.primaryTextLight,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _onSearch(),
                    decoration: InputDecoration(
                      hintText: 'Cari nama anggota...',
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        size: 18,
                        color: AppColors.secondaryTextLight,
                      ),
                      filled: true,
                      fillColor: AppColors.secondaryBackgroundLight,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(LucideIcons.search, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: _showSortSheet,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryLight.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.swap_vert_rounded,
                        size: 16,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _sortLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.primaryLight,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(textTheme)),
        ],
      ),
    );
  }

  Widget _buildBody(TextTheme textTheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.secondaryTextLight,
              ),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat data',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.primaryTextLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _fetchData(reset: true),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.user,
              size: 40,
              color: AppColors.secondaryTextLight.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada pendaftaran baru',
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.primaryTextLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Semua pendaftaran sudah diproses.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    final sortedItems = _sortedItems;

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: () => _fetchData(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: sortedItems.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= sortedItems.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = sortedItems[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openDetail(item),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackgroundLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.user,
                        size: 20,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nama,
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.primaryTextLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'NIK: ${item.nik?.isNotEmpty == true ? item.nik : '-'}',
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Masuk: ${_formatDate(item.tanggalMasuk)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryTextLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.secondaryTextLight,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
