import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/model/list_pengajuan.dart';
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/theme.dart';

class AdminPencairanListPage extends StatefulWidget {
  const AdminPencairanListPage({super.key});

  @override
  State<AdminPencairanListPage> createState() => _AdminPencairanListPageState();
}

class _AdminPencairanListPageState extends State<AdminPencairanListPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<PengajuanItem> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _page = 1;
  bool _hasMore = true;
  String _searchQuery = '';
  String? _statusFilter; // null = semua

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

  static const _statusOptions = <String?>[
    null,
    'PENDING',
    'DISETUJUI',
    'DITOLAK',
    'DIVERIFIKASI',
  ];

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
      final response = await _apiService.getGridPengajuanPencairan(
        page: _page,
        perPage: 10,
        search: _searchQuery,
        statusPengambilan: _statusFilter,
      );

      if (!mounted) return;

      setState(() {
        _items.addAll(response.data);
        if (response.lastPage != null) {
          _hasMore = response.hasMore;
        } else {
          _hasMore = response.data.length >= 10;
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

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppColors.warningLight;
      case 'DISETUJUI':
        return AppColors.successLight;
      case 'DITOLAK':
        return AppColors.errorLight;
      case 'DIVERIFIKASI':
        return AppColors.infoLight;
      default:
        return AppColors.secondaryTextLight;
    }
  }

  String _statusLabel(String? status) {
    if (status == null) return 'Semua';
    return status;
  }

  void _openDetail(PengajuanItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryBackgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final textTheme = AppTheme.textThemeLight;
        final anggota = item.masterAnggota;
        final jenis = item.jenisTabungan;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Detail Pencairan',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTextLight,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(
                            item.statusPengambilan,
                          ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.statusPengambilan,
                          style: textTheme.labelSmall?.copyWith(
                            color: _statusColor(item.statusPengambilan),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailRow('Anggota', anggota?.nama ?? '-'),
                  _detailRow('No. Anggota', anggota?.nomorAnggota ?? '-'),
                  _detailRow('NIK', anggota?.nik ?? '-'),
                  _detailRow('Jenis Tabungan', jenis?.nama ?? '-'),
                  _detailRow(
                    'Jumlah Diajukan',
                    _currencyFormat.format(item.jumlahDiambil),
                  ),
                  _detailRow(
                    'Jumlah Disetujui',
                    _currencyFormat.format(item.jumlahDisetujui ?? 0),
                  ),
                  _detailRow(
                    'Rekening',
                    '${item.rekeningBank} - ${item.rekeningNo}',
                  ),
                  _detailRow(
                    'Tgl Pengajuan',
                    item.tglPengajuan != null
                        ? _dateFormat.format(item.tglPengajuan!.toLocal())
                        : '-',
                  ),
                  _detailRow(
                    'Tgl Pencairan',
                    item.tglPencairan != null
                        ? _dateFormat.format(item.tglPencairan!.toLocal())
                        : '-',
                  ),
                  _detailRow('Catatan User', item.catatanUser ?? '-'),
                  _detailRow('Catatan Approver', item.catatanApprover ?? '-'),
                  const SizedBox(height: 8),
                  Text(
                    'Menunggu API approval.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryTextLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    final textTheme = AppTheme.textThemeLight;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryTextLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryTextLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTheme.textThemeLight;

    return Scaffold(
      backgroundColor: AppColors.primaryBackgroundLight,
      appBar: AppBar(
        title: Text(
          'Pencairan Tabungan',
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
                      hintText: 'Cari nama / nomor anggota...',
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
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statusOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = _statusOptions[index];
                final selected = _statusFilter == status;
                return ChoiceChip(
                  label: Text(_statusLabel(status)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _statusFilter = status);
                    _fetchData(reset: true);
                  },
                  selectedColor: AppColors.primaryLight.withOpacity(0.18),
                  backgroundColor: AppColors.secondaryBackgroundLight,
                  labelStyle: textTheme.labelSmall?.copyWith(
                    color:
                        selected
                            ? AppColors.primaryLight
                            : AppColors.secondaryTextLight,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color:
                        selected
                            ? AppColors.primaryLight
                            : Colors.transparent,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
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
              Icons.account_balance_wallet_outlined,
              size: 40,
              color: AppColors.secondaryTextLight.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada pengajuan pencairan',
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.primaryTextLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba ubah filter atau kata kunci pencarian.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: () => _fetchData(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _items.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = _items[index];
          final anggota = item.masterAnggota;
          final statusColor = _statusColor(item.statusPengambilan);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            anggota?.nama ?? 'Anggota',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.primaryTextLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.statusPengambilan,
                            style: textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No. ${anggota?.nomorAnggota ?? '-'} · ${item.jenisTabungan?.nama ?? '-'}',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currencyFormat.format(item.jumlahDiambil),
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          item.tglPengajuan != null
                              ? _dateFormat.format(item.tglPengajuan!.toLocal())
                              : '-',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryTextLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.rekeningBank} · ${item.rekeningNo}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryTextLight,
                      ),
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
