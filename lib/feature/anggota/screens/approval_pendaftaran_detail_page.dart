import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/model/anggota_registrasi_response.dart';
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/theme.dart';

class ApprovalPendaftaranDetailPage extends StatefulWidget {
  final AnggotaRegistrasiItem anggota;

  const ApprovalPendaftaranDetailPage({super.key, required this.anggota});

  @override
  State<ApprovalPendaftaranDetailPage> createState() =>
      _ApprovalPendaftaranDetailPageState();
}

class _ApprovalPendaftaranDetailPageState
    extends State<ApprovalPendaftaranDetailPage> {
  final ApiService _apiService = ApiService();
  bool _isApproving = false;
  bool _isAssigning = false;
  bool _alreadyApproved = false;
  bool _alreadyAssigned = false;

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == '-') return '-';
    try {
      final date = DateTime.parse(raw);
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return raw.split('T').first;
    }
  }

  String _display(String? value) {
    if (value == null || value.trim().isEmpty || value.trim() == '-') {
      return '-';
    }
    return value;
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: AppTheme.textThemeLight.titleMedium,
            ),
            content: Text(message, style: AppTheme.textThemeLight.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batal',
                  style: AppTheme.textThemeLight.labelLarge?.copyWith(
                    color: AppColors.secondaryTextLight,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  confirmLabel,
                  style: AppTheme.textThemeLight.labelLarge?.copyWith(
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
    );
    return result == true;
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.errorLight : AppColors.successLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _setujuiAnggota() async {
    final ok = await _confirm(
      title: 'Setujui Pendaftaran',
      message:
          'Setujui pendaftaran ${widget.anggota.nama} sebagai anggota koperasi?',
      confirmLabel: 'Setujui',
    );
    if (!ok) return;

    setState(() => _isApproving = true);
    try {
      final response = await _apiService.setujuiAnggota(
        widget.anggota.pAnggotaId,
      );
      if (!mounted) return;

      final success = response['success'] != false;
      final message =
          response['message']?.toString() ??
          'Pendaftaran anggota berhasil disetujui.';

      if (success) {
        setState(() => _alreadyApproved = true);
        _showSnack(message);

        final assignNow = await _confirm(
          title: 'Buat Akun User?',
          message:
              'Anggota sudah disetujui. Assign ${widget.anggota.nama} sebagai user aplikasi sekarang?',
          confirmLabel: 'Assign User',
        );
        if (assignNow) {
          await _assignUser(skipConfirm: true);
        } else if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showSnack(message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Future<void> _assignUser({bool skipConfirm = false}) async {
    if (!skipConfirm) {
      final ok = await _confirm(
        title: 'Assign sebagai User',
        message:
            'Buat akun login untuk ${widget.anggota.nama}? Pastikan anggota sudah disetujui.',
        confirmLabel: 'Assign',
      );
      if (!ok) return;
    }

    setState(() => _isAssigning = true);
    try {
      final response = await _apiService.assignAnggotaToUser(
        widget.anggota.pAnggotaId,
      );
      if (!mounted) return;

      final success = response['success'] != false;
      final message =
          response['message']?.toString() ??
          'Anggota berhasil di-assign sebagai user.';

      if (success) {
        setState(() {
          _alreadyAssigned = true;
          _alreadyApproved = true;
        });
        _showSnack(message);
        Navigator.pop(context, true);
      } else {
        _showSnack(message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  Widget _infoRow(String label, String value) {
    final textTheme = AppTheme.textThemeLight;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
    final item = widget.anggota;
    final busy = _isApproving || _isAssigning;

    return Scaffold(
      backgroundColor: AppColors.primaryBackgroundLight,
      appBar: AppBar(
        title: Text(
          'Detail Pendaftaran',
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.user,
                            color: AppColors.primaryLight,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.nama,
                                style: textTheme.titleMedium?.copyWith(
                                  color: AppColors.primaryTextLight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${item.pAnggotaId}',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Data Anggota',
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryTextLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackgroundLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Nomor Anggota', _display(item.nomorAnggota)),
                        _infoRow('NIK', _display(item.nik)),
                        _infoRow('No. HP', _display(item.noHp)),
                        _infoRow('Email', _display(item.email)),
                        _infoRow(
                          'Tempat Lahir',
                          _display(item.tempatLahir),
                        ),
                        _infoRow('Tanggal Lahir', _formatDate(item.tglLahir)),
                        _infoRow(
                          'Tanggal Masuk',
                          _formatDate(item.tanggalMasuk),
                        ),
                        _infoRow('Alamat', _display(item.alamat)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.primaryBackgroundLight,
                border: Border(
                  top: BorderSide(
                    color: AppColors.secondaryBackgroundLight,
                  ),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          busy || _alreadyApproved ? null : _setujuiAnggota,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor:
                            AppColors.primaryLight.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child:
                          _isApproving
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                _alreadyApproved
                                    ? 'Sudah Disetujui'
                                    : 'Setujui Anggota',
                                style: textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed:
                          busy || _alreadyAssigned
                              ? null
                              : () => _assignUser(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryLight,
                        side: BorderSide(
                          color:
                              _alreadyAssigned
                                  ? AppColors.secondaryTextLight.withOpacity(
                                    0.3,
                                  )
                                  : AppColors.primaryLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child:
                          _isAssigning
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primaryLight,
                                ),
                              )
                              : Text(
                                _alreadyAssigned
                                    ? 'Sudah Menjadi User'
                                    : 'Assign sebagai User',
                                style: textTheme.labelLarge?.copyWith(
                                  color:
                                      _alreadyAssigned
                                          ? AppColors.secondaryTextLight
                                          : AppColors.primaryLight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
