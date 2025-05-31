import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk NumberFormat dan DateFormat
import 'package:kkba_mobile/model/pinjaman_list.dart'; // Sesuaikan path import
import 'package:kkba_mobile/service/api_service.dart'; // Sesuaikan path import
import 'package:kkba_mobile/model/jenis_pinjaman.dart'; // Sesuaikan path import (dari FormWizard)
import 'package:kkba_mobile/model/keperluan_pinjaman.dart'; // Sesuaikan path import (dari FormWizard)
import 'package:kkba_mobile/theme.dart';
// Model StatusPengajuanFilterModel sekarang ada di pinjaman_list_models.dart
// jadi tidak perlu import terpisah lagi.

class DaftarPinjamanScreen extends StatefulWidget {
  const DaftarPinjamanScreen({Key? key}) : super(key: key);

  @override
  _DaftarPinjamanScreenState createState() => _DaftarPinjamanScreenState();
}

class _DaftarPinjamanScreenState extends State<DaftarPinjamanScreen> {
  List<PinjamanDetailModel> _pinjamanList = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int? _lastPage;
  bool _isFetchingMore = false;
  bool _isLoadingFilters = false;

  int? _selectedStatusId;
  int? _selectedJenisPinjamanId;
  String? _selectedKeperluanId;
  int? _selectedMonth;
  int? _selectedYear;

  List<MasterStatusPengajuanSimpleModel> _statusOptions = [];
  List<JenisPinjamanModel> _jenisPinjamanOptions = [];
  List<KeperluanPinjamanModel> _keperluanOptions = [];

  final List<int> _monthOptions = List.generate(12, (i) => i + 1);
  final List<int> _yearOptions = List.generate(
    10,
    (i) => DateTime.now().year - i,
  );

  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();

  Map<String, Color> _statusColors = {};
  Map<String, Color> _statusTextColors = {};

  @override
  void initState() {
    super.initState();
    // Inisialisasi warna status. Sesuaikan nama status dan AppColors Anda.
    // Key harus cocok dengan pinjaman.masterStatusPengajuan.nama
    _statusColors = {
      "Pending": AppColors.warningLight.withOpacity(0.15),
      "Under Review": AppColors.warningLight.withOpacity(0.15),
      "Approve": AppColors.successLight.withOpacity(0.15),
      "Disetujui": AppColors.successLight.withOpacity(0.15),
      "On installment": AppColors.infoLight.withOpacity(0.15),
      "Dicairkan": AppColors.infoLight.withOpacity(0.15),
      "Paid off": AppColors.successLight.withOpacity(
        0.2,
      ), // Lebih gelap sedikit untuk paid off
      "Lunas": AppColors.successLight.withOpacity(0.2),
      "Reject": AppColors.errorLight.withOpacity(0.15),
      "Ditolak": AppColors.errorLight.withOpacity(0.15),
      "Cancelled": Colors.grey.shade200, // Warna netral
      "Batal": Colors.grey.shade200,
      "Baru": AppColors.primaryLight.withOpacity(0.1),
    };

    _statusTextColors = {
      "Pending":
          AppColors
              .warningLight, // Sebaiknya warna yang lebih gelap dari warningLight
      "Under Review": AppColors.warningLight,
      "Approve":
          AppColors
              .successLight, // Sebaiknya warna yang lebih gelap dari successLight
      "Disetujui": AppColors.successLight,
      "On installment":
          AppColors
              .infoLight, // Sebaiknya warna yang lebih gelap dari infoLight
      "Dicairkan": AppColors.infoLight,
      "Paid off":
          AppColors
              .successLight, // Sebaiknya warna yang lebih gelap dari successLight
      "Lunas": AppColors.successLight,
      "Reject":
          AppColors
              .errorLight, // Sebaiknya warna yang lebih gelap dari errorLight
      "Ditolak": AppColors.errorLight,
      "Cancelled": AppColors.secondaryTextLight,
      "Batal": AppColors.secondaryTextLight,
      "Baru": AppColors.primaryLight,
    };

    _loadInitialData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          !_isFetchingMore &&
          (_lastPage == null || _currentPage < _lastPage!)) {
        _fetchPinjamanData(page: _currentPage + 1);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() => _isLoading = true);
    await _fetchFilterOptions();
    await _fetchPinjamanData(refresh: true);
  }

  Future<void> _fetchFilterOptions() async {
    if (mounted) setState(() => _isLoadingFilters = true);
    try {
      final results = await Future.wait([
        ApiService.getMasterStatusPengajuan(),
        _apiService.getMasterJenisPinjaman(),
        _apiService.getMasterKeperluanPinjaman(),
      ]);
      if (mounted) {
        setState(() {
          _statusOptions = results[0] as List<MasterStatusPengajuanSimpleModel>;
          _jenisPinjamanOptions = results[1] as List<JenisPinjamanModel>;
          _keperluanOptions = results[2] as List<KeperluanPinjamanModel>;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMessage =
            "Gagal memuat opsi filter: ${e.toString().replaceFirst("Exception: ", "")}";
        setState(() {
          _errorMessage = errorMessage;
        });
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoadingFilters = false);
    }
  }

  Future<void> _fetchPinjamanData({int page = 1, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      if (mounted) {
        setState(() {
          _pinjamanList.clear();
          _lastPage = null;
          _isLoading = true;
          _errorMessage = null;
        });
      }
    } else {
      if (_isFetchingMore || _isLoading) return;
      if (mounted) setState(() => _isFetchingMore = true);
    }
    try {
      final response = await ApiService.getListPengajuanPinjaman(
        page: _currentPage,
        pStatusPengajuanId: _selectedStatusId,
        pJenisPinjamanId: _selectedJenisPinjamanId,
        pPinjamanKeperluanId: _selectedKeperluanId,
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (mounted) {
        setState(() {
          if (response.success) {
            _pinjamanList.addAll(response.data.data);
            _lastPage = response.data.lastPage;
            _currentPage = response.data.currentPage;
            if (response.data.data.isEmpty && refresh) {
              _errorMessage =
                  "Tidak ada data pinjaman ditemukan untuk filter ini.";
            }
          } else {
            _errorMessage = response.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? currentValue,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon:
              prefixIcon != null
                  ? Icon(
                    prefixIcon,
                    color: AppColors.secondaryTextLight,
                    size: 20,
                  )
                  : null,
          filled: true,
          fillColor: AppColors.secondaryBackgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade300.withOpacity(0.7),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryLight, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          labelStyle: TextStyle(
            color: AppColors.secondaryTextLight,
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: AppColors.secondaryTextLight.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        isExpanded: true,
        value: currentValue,
        items: items,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 15,
          color: AppColors.primaryTextLight,
          fontWeight: FontWeight.w500,
        ),
        icon: Icon(
          Icons.arrow_drop_down_rounded,
          color: AppColors.secondaryTextLight,
        ),
        dropdownColor: AppColors.primaryBackgroundLight,
      ),
    );
  }

  void _applyFilters() {
    _fetchPinjamanData(refresh: true);
  }

  void _resetFilters() {
    setState(() {
      _selectedStatusId = null;
      _selectedJenisPinjamanId = null;
      _selectedKeperluanId = null;
      _selectedMonth = null;
      _selectedYear = null;
    });
    _fetchPinjamanData(refresh: true);
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  // _getTextColorForStatus tidak lagi digunakan secara langsung jika _statusTextColors dipakai
  // Color _getTextColorForStatus(String statusNama) {
  //   if (statusNama.toLowerCase().contains('approve') || statusNama.toLowerCase().contains('disetujui') || statusNama.toLowerCase().contains('lunas') || statusNama.toLowerCase().contains('paid off')) {
  //     return AppColors.successLight;
  //   } else if (statusNama.toLowerCase().contains('pending') || statusNama.toLowerCase().contains('under review')) {
  //     return AppColors.warningLight;
  //   } else if (statusNama.toLowerCase().contains('reject') || statusNama.toLowerCase().contains('ditolak')) {
  //     return AppColors.errorLight;
  //   }
  //   return AppColors.primaryTextLight;
  // }

  @override
  Widget build(BuildContext context) {
    final textTheme =
        Theme.of(context).textTheme; // Mengambil textTheme dari context

    return Scaffold(
      backgroundColor: AppColors.primaryBackgroundLight,
      appBar: AppBar(
        title: Text(
          'Daftar Pengajuan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryLight,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 1,
      ),
      body: Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              iconColor: AppColors.primaryLight,
              collapsedIconColor: AppColors.secondaryTextLight,
              initiallyExpanded: false,
              title: Text(
                'Filter Pencarian',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryTextLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child:
                      _isLoadingFilters
                          ? Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryLight,
                            ),
                          )
                          : Column(
                            children: [
                              _buildFilterDropdown<int?>(
                                label: 'Status Pengajuan',
                                hint: 'Semua Status',
                                currentValue: _selectedStatusId,
                                prefixIcon: Icons.flag_outlined,
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text("Semua Status"),
                                  ),
                                  ..._statusOptions.map(
                                    (status) => DropdownMenuItem<int?>(
                                      value: status.pStatusPengajuanId,
                                      child: Text(status.nama ?? 'N/A'),
                                    ),
                                  ),
                                ],
                                onChanged:
                                    (value) => setState(
                                      () => _selectedStatusId = value,
                                    ),
                              ),
                              _buildFilterDropdown<int?>(
                                label: 'Jenis Pinjaman',
                                hint: 'Semua Jenis',
                                prefixIcon: Icons.category_outlined,
                                currentValue: _selectedJenisPinjamanId,
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text("Semua Jenis"),
                                  ),
                                  ..._jenisPinjamanOptions.map(
                                    (jenis) => DropdownMenuItem<int?>(
                                      value: jenis.id,
                                      child: Text(jenis.nama),
                                    ),
                                  ),
                                ],
                                onChanged:
                                    (value) => setState(
                                      () => _selectedJenisPinjamanId = value,
                                    ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: Icon(
                                          Icons.clear_all_rounded,
                                          size: 18,
                                        ),
                                        onPressed: _resetFilters,
                                        label: Text("Reset"),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              AppColors.secondaryTextLight,
                                          side: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: Icon(
                                          Icons.filter_alt_rounded,
                                          size: 18,
                                        ),
                                        onPressed: _applyFilters,
                                        label: Text("Terapkan"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryLight,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          elevation: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300.withOpacity(0.5)),
          Expanded(
            child:
                _isLoading && _pinjamanList.isEmpty
                    ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryLight,
                      ),
                    )
                    : _errorMessage != null && _pinjamanList.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          '$_errorMessage',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryTextLight,
                          ),
                        ),
                      ),
                    )
                    : _pinjamanList.isEmpty
                    ? Center(
                      child: Text(
                        'Tidak ada data pengajuan.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryTextLight,
                        ),
                      ),
                    )
                    : RefreshIndicator(
                      color: AppColors.primaryLight,
                      onRefresh: () => _fetchPinjamanData(refresh: true),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        itemCount:
                            _pinjamanList.length + (_isFetchingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _pinjamanList.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            );
                          }
                          final pinjaman = _pinjamanList[index];
                          final statusNama =
                              pinjaman.masterStatusPengajuan.nama ?? 'N/A';
                          final statusBgColor =
                              _statusColors[statusNama] ??
                              Colors.grey.shade300.withOpacity(0.5);
                          final statusTextColor =
                              _statusTextColors[statusNama] ??
                              AppColors.primaryTextLight;

                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            elevation: 1.5,
                            color:
                                AppColors
                                    .secondaryBackgroundLight, // Warna Card
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          pinjaman.nomorPinjaman ?? 'N/A',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    AppColors.primaryTextLight,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusBgColor,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Text(
                                          statusNama,
                                          style: textTheme.labelSmall?.copyWith(
                                            color: statusTextColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  _buildInfoRow(
                                    Icons.person_outline_rounded,
                                    'Anggota:',
                                    '${pinjaman.masterAnggota.nama ?? 'N/A'} (${pinjaman.masterAnggota.nomorAnggota ?? 'N/A'})',
                                  ),
                                  _buildInfoRow(
                                    Icons.category_outlined,
                                    'Jenis:',
                                    pinjaman.masterJenisPinjaman.nama ?? 'N/A',
                                  ),
                                  SizedBox(height: 6),
                                  _buildInfoRow(
                                    Icons.attach_money_rounded,
                                    'Jumlah Diajukan:',
                                    'Rp ${NumberFormat.decimalPattern('id_ID').format(pinjaman.raJumlahPinjaman ?? 0)}',
                                  ),
                                  if (pinjaman.riJumlahPinjaman != null &&
                                      pinjaman.riJumlahPinjaman! > 0)
                                    _buildInfoRow(
                                      Icons.check_circle_outline_rounded,
                                      'Jumlah Disetujui:',
                                      'Rp ${NumberFormat.decimalPattern('id_ID').format(pinjaman.riJumlahPinjaman)}',
                                    ),
                                  _buildInfoRow(
                                    Icons.timer_outlined,
                                    'Tenor:',
                                    '${pinjaman.tenor ?? '-'} bulan',
                                  ),
                                  if (pinjaman.pinjamanKeperluanNama.isNotEmpty)
                                    _buildInfoRow(
                                      Icons.list_alt_rounded,
                                      'Keperluan:',
                                      pinjaman.pinjamanKeperluanNama.join(', '),
                                    ),
                                  SizedBox(height: 6),
                                  _buildInfoRow(
                                    Icons.calendar_today_outlined,
                                    'Tgl Pengajuan:',
                                    DateFormat(
                                      'dd MMM yyyy, HH:mm',
                                      'id_ID',
                                    ).format(pinjaman.createdAt),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryLight),
          SizedBox(width: 8),
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.secondaryTextLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.primaryTextLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
