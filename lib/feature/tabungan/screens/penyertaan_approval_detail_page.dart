// lib/feature/tabungan/screens/penyertaan_approval_detail_page.dart
// (FILE BARU - VERSI DESAIN MODERN)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkba_mobile/model/list_penyertaan_response.dart';
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/theme.dart';

class PenyertaanApprovalDetailPage extends StatefulWidget {
  final Penyertaan penyertaanData;

  const PenyertaanApprovalDetailPage({Key? key, required this.penyertaanData})
    : super(key: key);

  @override
  State<PenyertaanApprovalDetailPage> createState() =>
      _PenyertaanApprovalDetailPageState();
}

class _PenyertaanApprovalDetailPageState
    extends State<PenyertaanApprovalDetailPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  final _catatanController = TextEditingController();
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Isi catatan approver jika sudah ada
    if (widget.penyertaanData.catatanApprover != null) {
      _catatanController.text = widget.penyertaanData.catatanApprover!;
    }
  }

  // Fungsi untuk mendapatkan warna status
  Color _getStatusColor(String status) {
    String upperStatus = status.toUpperCase();
    if (upperStatus == 'PENDING') return AppColors.warningLight;
    if (upperStatus == 'APPROVED') return AppColors.successLight;
    if (upperStatus == 'REJECTED' || upperStatus == 'CANCELED')
      return AppColors.errorLight;
    return AppColors.secondaryTextLight;
  }

  // Widget Card Detail yang terpusat dan minimalis
  Widget _buildDetailCard(
    String label,
    String value, {
    TextStyle? valueStyle,
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.textThemeLight.labelSmall?.copyWith(
            color: AppColors.secondaryTextLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style:
              valueStyle ??
              AppTheme.textThemeLight.bodyLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Widget untuk menampilkan Catatan
  Widget _buildNotesSection(String title, String note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.textThemeLight.labelMedium),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryBackgroundLight),
          ),
          child: Text(note, style: AppTheme.textThemeLight.bodyMedium),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Implementasikan logika approve/reject Anda di sini
  void _handleApproval(String newStatus) async {
    // Validasi sederhana
    if (newStatus == "REJECTED" && _catatanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan wajib diisi jika menolak pengajuan.'),
          backgroundColor: AppColors.errorLight,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Panggil API approval dari api_service.dart
      await _apiService.approvePenyertaan(
        id: widget.penyertaanData.tTabunganPenyertaanId,
        pJenisTabunganId: widget.penyertaanData.jenisTabungan.id,
        statusPenyertaan: newStatus,
        jumlah: widget.penyertaanData.jumlah.toInt(),
        tanggalPenyertaan: widget.penyertaanData.penyertaanDate
            .toIso8601String()
            .split('T')
            .first
            .replaceAll('-', '/'), // Format YYYY/MM/DD
        catatanApprover: _catatanController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengajuan berhasil di-$newStatus'),
            backgroundColor: AppColors.successLight,
          ),
        );
        // Kembalikan 'true' untuk memberitahu list sebelumnya agar refresh
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal melakukan approval: $e'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 'item' sekarang adalah objek 'Penyertaan'
    final item = widget.penyertaanData;
    final bool isPending = item.statusPenyertaan.toUpperCase() == 'PENDING';
    final statusColor = _getStatusColor(item.statusPenyertaan);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Approval Penyertaan'),
        backgroundColor: AppColors.primaryBackgroundLight,
        foregroundColor: AppColors.primaryTextLight,
        elevation: 0,
      ),
      backgroundColor: AppColors.primaryBackgroundLight,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status Pengajuan',
                          style: AppTheme.textThemeLight.titleMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.statusPenyertaan,
                            style: AppTheme.textThemeLight.labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Card Detail Utama
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailCard(
                            'ANGGOTA',
                            item.masterAnggota.nama,
                            valueStyle: AppTheme.textThemeLight.titleLarge
                                ?.copyWith(
                                  color: AppColors.primaryTextLight,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Divider(
                            color: AppColors.primaryBackgroundLight,
                          ),
                          const SizedBox(height: 8),

                          _buildDetailCard(
                            'JENIS TABUNGAN',
                            item.jenisTabungan.nama,
                          ),

                          _buildDetailCard(
                            'TANGGAL PENGAJUAN',
                            DateFormat(
                              'd MMMM yyyy',
                              'id_ID',
                            ).format(item.penyertaanDate),
                          ),

                          // Jumlah Pengajuan (Dibuat lebih menonjol)
                          Text(
                            'JUMLAH PENGAJUAN',
                            style: AppTheme.textThemeLight.labelSmall?.copyWith(
                              color: AppColors.secondaryTextLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormatter.format(item.jumlah),
                            style: AppTheme.textThemeLight.headlineSmall?.copyWith(
                              color:
                                  AppColors
                                      .successLight, // Warna hijau untuk uang masuk
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Catatan User
                    if (item.catatanUser != null &&
                        item.catatanUser!.isNotEmpty)
                      _buildNotesSection('Catatan User', item.catatanUser!),

                    // Area Approval/Catatan Approver
                    if (isPending) ...[
                      TextFormField(
                        controller: _catatanController,
                        decoration: InputDecoration(
                          labelText: 'Catatan Approval (Wajib jika menolak)',
                          hintText: 'Tuliskan alasan atau persetujuan...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Tombol Aksi
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _isLoading
                                      ? null
                                      : () => _handleApproval("REJECTED"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.errorLight,
                                side: const BorderSide(
                                  color: AppColors.errorLight,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Tolak',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading
                                      ? null
                                      : () => _handleApproval("APPROVED"),
                              style: ElevatedButton.styleFrom(
                                // Menggunakan warna primary light sesuai permintaan
                                backgroundColor: AppColors.primaryLight,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Setujui',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Catatan Approver jika sudah tidak pending
                      if (item.catatanApprover != null &&
                          item.catatanApprover!.isNotEmpty)
                        _buildNotesSection(
                          'Catatan Dari Approver',
                          item.catatanApprover!,
                        ),
                    ],
                  ],
                ),
              ),
    );
  }
}
