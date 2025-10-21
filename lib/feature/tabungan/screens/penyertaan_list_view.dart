// lib/feature/penyertaan/widgets/penyertaan_list_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../service/api_service.dart';
import '../../../model/list_penyertaan_response.dart';
import '../../../theme.dart';

class PenyertaanListView extends StatefulWidget {
  const PenyertaanListView({Key? key}) : super(key: key);

  @override
  PenyertaanListViewState createState() => PenyertaanListViewState();
}

class PenyertaanListViewState extends State<PenyertaanListView> {
  late Future<ListPenyertaanResponse> _futurePenyertaan;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadPenyertaan();
  }

  void refreshData() {
    _loadPenyertaan();
  }

  void _loadPenyertaan() {
    setState(() {
      _futurePenyertaan = _apiService.getListPenyertaan();
    });
  }

  Map<String, dynamic> _getTabunganStyle(String nama) {
    String lowerCaseNama = nama.toLowerCase();
    if (lowerCaseNama.contains('pokok'))
      return {'icon': LucideIcons.shieldCheck, 'color': Colors.blue.shade700};
    if (lowerCaseNama.contains('wajib'))
      return {'icon': LucideIcons.star, 'color': Colors.amber.shade800};
    if (lowerCaseNama.contains('sukarela'))
      return {'icon': LucideIcons.piggyBank, 'color': Colors.green.shade700};
    return {'icon': LucideIcons.landmark, 'color': Colors.grey.shade600};
  }

  Color _getStatusColor(String status) => AppColors.secondaryTextLight;

  Future<bool?> _handleCancelConfirmation(String penyertaanId) async {
    return await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Konfirmasi Pembatalan',
              style: AppTheme.textThemeLight.titleMedium,
            ),
            content: Text(
              'Anda yakin ingin membatalkan pengajuan ini?',
              style: AppTheme.textThemeLight.bodyMedium,
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Tidak',
                  style: AppTheme.textThemeLight.labelLarge?.copyWith(
                    color: AppColors.secondaryTextLight,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(
                  'Ya, Batalkan',
                  style: AppTheme.textThemeLight.labelLarge?.copyWith(
                    color: AppColors.errorLight,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return RefreshIndicator(
      onRefresh: () async => _loadPenyertaan(),
      color: AppColors.primaryLight,
      child: FutureBuilder<ListPenyertaanResponse>(
        future: _futurePenyertaan,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.data.data.isEmpty)
            return Center(child: Text('Belum ada data pengajuan.'));

          final penyertaanList = snapshot.data!.data.data;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 16.0,
            ),
            itemCount: penyertaanList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = penyertaanList[index];
              final tabunganStyle = _getTabunganStyle(item.jenisTabungan.nama);

              return Dismissible(
                key: Key(item.tTabunganPenyertaanId),
                direction: DismissDirection.endToStart,
                background: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(LucideIcons.trash2, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Batalkan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (item.statusPenyertaan.toUpperCase() != 'PENDING') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Hanya pengajuan PENDING yang bisa dibatalkan.',
                        ),
                        backgroundColor: AppColors.infoLight,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return false;
                  }
                  bool? confirm = await _handleCancelConfirmation(
                    item.tTabunganPenyertaanId,
                  );
                  if (confirm == true) {
                    try {
                      await _apiService.cancelPenyertaan(
                        item.tTabunganPenyertaanId,
                      );
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pengajuan berhasil dibatalkan.'),
                            backgroundColor: AppColors.successLight,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      return true;
                    } catch (e) {
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal membatalkan: $e'),
                            backgroundColor: AppColors.errorLight,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      return false;
                    }
                  }
                  return false;
                },
                onDismissed: (direction) => refreshData(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: tabunganStyle['color'].withOpacity(0.1),
                      child: Icon(
                        tabunganStyle['icon'],
                        color: tabunganStyle['color'],
                        size: 22,
                      ),
                    ),
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.jenisTabungan.nama,
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'd MMM',
                              'id_ID',
                            ).format(item.penyertaanDate),
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.secondaryTextLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencyFormatter.format(item.jumlah),
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryTextLight,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.masterAnggota.nama,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryTextLight,
                          ),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          item.statusPenyertaan,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.statusPenyertaan,
                        style: textTheme.labelSmall?.copyWith(
                          color: _getStatusColor(item.statusPenyertaan),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
