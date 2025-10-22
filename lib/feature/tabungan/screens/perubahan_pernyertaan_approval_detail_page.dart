// lib/feature/perubahan_penyertaan/screens/perubahan_penyertaan_approval_detail_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Asumsi: Anda memiliki model untuk Perubahan Penyertaan
import 'package:kkba_mobile/model/list_perubahan_penyertaan_response.dart';
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Ganti nama model sesuai model Anda, misal: PerubahanPenyertaan
class PerubahanPenyertaanApprovalDetailPage extends StatefulWidget {
  final PerubahanPenyertaan perubahanData;

  const PerubahanPenyertaanApprovalDetailPage({
    Key? key,
    required this.perubahanData,
  }) : super(key: key);

  @override
  State<PerubahanPenyertaanApprovalDetailPage> createState() =>
      _PerubahanPenyertaanApprovalDetailPageState();
}

class _PerubahanPenyertaanApprovalDetailPageState
    extends State<PerubahanPenyertaanApprovalDetailPage> {
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
    if (widget.perubahanData.catatanApprover != null) {
      _catatanController.text = widget.perubahanData.catatanApprover!;
    }
  }

  // Implementasikan logika approve/reject
  void _handleApproval(String newStatus) async {
    final item = widget.perubahanData;

    // Validasi sederhana: Catatan wajib jika menolak
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
      // Panggil API approval perubahan penyertaan dari api_service.dart
      await _apiService.approvePerubahanPenyertaan(
        id: item.id, // Asumsi id adalah ID Perubahan Penyertaan
        pJenisTabunganId: item.jenisTabungan.id, // Menggunakan properti '.id'
        statusPerubahan: newStatus, // "APPROVED" or "REJECTED"
        nilaiBaru: item.nilaiBaru.toInt(),
        nilaiSebelum: item.nilaiSebelum?.toInt(), // Kirim nilaiSebelum jika ada
        validFrom: item.validFrom
            .toIso8601String()
            .split('T')
            .first
            .replaceAll('-', '/'), // Format YYYY/MM/DD
        catatanApprover: _catatanController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengajuan perubahan berhasil di-$newStatus'),
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

  @override
  Widget build(BuildContext context) {
    final item = widget.perubahanData;
    final bool isPending = item.statusPerubahan.toUpperCase() == 'PENDING';
    final statusColor = _getStatusColor(item.statusPerubahan);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Approval'),
        backgroundColor: AppColors.primaryBackgroundLight,
        foregroundColor: AppColors.primaryTextLight,
        elevation: 0,
      ),
      backgroundColor:
          AppColors.primaryBackgroundLight, // Background lebih terang
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
                            item.statusPerubahan,
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
                            'TANGGAL EFEKTIF',
                            DateFormat(
                              'd MMMM yyyy',
                              'id_ID',
                            ).format(item.validFrom),
                          ),

                          Text(
                            'PERUBAHAN NILAI',
                            style: AppTheme.textThemeLight.labelSmall?.copyWith(
                              color: AppColors.secondaryTextLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Perubahan Nilai Display
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (item.nilaiSebelum != null)
                                Text(
                                  currencyFormatter.format(item.nilaiSebelum),
                                  style: AppTheme.textThemeLight.titleMedium
                                      ?.copyWith(
                                        color: AppColors.errorLight,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                ),
                              if (item.nilaiSebelum != null)
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Icon(
                                    LucideIcons.arrowRight,
                                    size: 18,
                                    color: AppColors.secondaryTextLight,
                                  ),
                                ),
                              Text(
                                currencyFormatter.format(item.nilaiBaru),
                                style: AppTheme.textThemeLight.headlineSmall
                                    ?.copyWith(
                                      color: AppColors.successLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
