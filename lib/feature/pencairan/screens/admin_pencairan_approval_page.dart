import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kkba_mobile/model/list_pengajuan.dart';
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/theme.dart';

class AdminPencairanApprovalPage extends StatefulWidget {
  final PengajuanItem item;

  const AdminPencairanApprovalPage({super.key, required this.item});

  @override
  State<AdminPencairanApprovalPage> createState() =>
      _AdminPencairanApprovalPageState();
}

class _AdminPencairanApprovalPageState
    extends State<AdminPencairanApprovalPage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _catatanController = TextEditingController();

  bool _isSubmitting = false;
  DateTime _selectedDate = DateTime.now();

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateDisplayFormat = DateFormat('d MMMM yyyy', 'id_ID');
  final _dateApiFormat = DateFormat('yyyy-MM-dd');
  final _dateTimeFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

  bool get _isPending =>
      widget.item.statusPengambilan.toUpperCase() == 'PENDING';

  @override
  void initState() {
    super.initState();
    final jumlah =
        widget.item.jumlahDisetujui != null &&
                widget.item.jumlahDisetujui! > 0
            ? widget.item.jumlahDisetujui!
            : widget.item.jumlahDiambil;
    _jumlahController.text = NumberFormat.decimalPattern(
      'id_ID',
    ).format(jumlah);

    _selectedDate = widget.item.tglPencairan?.toLocal() ?? DateTime.now();
    _tanggalController.text = _dateDisplayFormat.format(_selectedDate);

    if (widget.item.catatanApprover != null) {
      _catatanController.text = widget.item.catatanApprover!;
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _tanggalController.dispose();
    _catatanController.dispose();
    super.dispose();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryLight,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryTextLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = _dateDisplayFormat.format(picked);
      });
    }
  }

  num _parseJumlah() {
    final clean = _jumlahController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return num.tryParse(clean) ?? 0;
  }

  Future<void> _submit(String status) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (status == 'DITOLAK' && _catatanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan wajib diisi jika menolak pengajuan.'),
          backgroundColor: AppColors.errorLight,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final jenisId = widget.item.jenisTabungan?.pJenisTabunganId;
    if (jenisId == null || jenisId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jenis tabungan tidak valid.'),
          backgroundColor: AppColors.errorLight,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              status == 'DISETUJUI' ? 'Setujui Pencairan?' : 'Tolak Pencairan?',
              style: AppTheme.textThemeLight.titleMedium,
            ),
            content: Text(
              status == 'DISETUJUI'
                  ? 'Pengajuan akan disetujui dengan jumlah ${_currencyFormat.format(_parseJumlah())}.'
                  : 'Pengajuan akan ditolak.',
              style: AppTheme.textThemeLight.bodyMedium,
            ),
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
                  status == 'DISETUJUI' ? 'Setujui' : 'Tolak',
                  style: AppTheme.textThemeLight.labelLarge?.copyWith(
                    color:
                        status == 'DISETUJUI'
                            ? AppColors.primaryLight
                            : AppColors.errorLight,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await _apiService.approvePencairan(
        id: widget.item.tTabunganPengambilanId,
        pJenisTabunganId: jenisId,
        statusPencairan: status,
        jumlahDisetujui: _parseJumlah(),
        tglPencairan: _dateApiFormat.format(_selectedDate),
        catatanApprover: _catatanController.text,
      );

      if (!mounted) return;

      final success = response['success'] != false;
      final message =
          response['message']?.toString() ??
          (status == 'DISETUJUI'
              ? 'Pencairan berhasil disetujui.'
              : 'Pencairan berhasil ditolak.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              success ? AppColors.successLight : AppColors.errorLight,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (success) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.errorLight,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.secondaryBackgroundLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorLight),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorLight, width: 1.5),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
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
    final item = widget.item;
    final anggota = item.masterAnggota;
    final statusColor = _statusColor(item.statusPengambilan);

    return Scaffold(
      backgroundColor: AppColors.primaryBackgroundLight,
      appBar: AppBar(
        title: Text(
          'Detail Pencairan',
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            anggota?.nama ?? 'Anggota',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.primaryTextLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
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
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackgroundLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _infoRow('No. Anggota', anggota?.nomorAnggota ?? '-'),
                          _infoRow('NIK', anggota?.nik ?? '-'),
                          _infoRow(
                            'Jenis Tabungan',
                            item.jenisTabungan?.nama ?? '-',
                          ),
                          _infoRow(
                            'Jumlah Diajukan',
                            _currencyFormat.format(item.jumlahDiambil),
                          ),
                          _infoRow(
                            'Rekening',
                            '${item.rekeningBank} - ${item.rekeningNo}',
                          ),
                          _infoRow(
                            'Tgl Pengajuan',
                            item.tglPengajuan != null
                                ? _dateTimeFormat.format(
                                  item.tglPengajuan!.toLocal(),
                                )
                                : '-',
                          ),
                          _infoRow('Catatan User', item.catatanUser ?? '-'),
                        ],
                      ),
                    ),
                    if (_isPending) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Form Approval',
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.primaryTextLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _jumlahController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            if (newValue.text.isEmpty) return newValue;
                            final number = int.tryParse(
                              newValue.text.replaceAll('.', ''),
                            );
                            if (number == null) return oldValue;
                            final formatted = NumberFormat.decimalPattern(
                              'id_ID',
                            ).format(number);
                            return TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                offset: formatted.length,
                              ),
                            );
                          }),
                        ],
                        decoration: _inputDecoration(
                          label: 'Jumlah Disetujui',
                          prefixText: 'Rp ',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jumlah disetujui wajib diisi';
                          }
                          if (_parseJumlah() <= 0) {
                            return 'Jumlah harus lebih dari 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _tanggalController,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: _inputDecoration(
                          label: 'Tanggal Pencairan',
                          suffixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.secondaryTextLight,
                          ),
                        ),
                        validator:
                            (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Tanggal pencairan wajib diisi'
                                    : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _catatanController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          label: 'Catatan Approver',
                          hint: 'Opsional, wajib jika menolak',
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackgroundLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            _infoRow(
                              'Jumlah Disetujui',
                              _currencyFormat.format(item.jumlahDisetujui ?? 0),
                            ),
                            _infoRow(
                              'Tgl Pencairan',
                              item.tglPencairan != null
                                  ? _dateTimeFormat.format(
                                    item.tglPencairan!.toLocal(),
                                  )
                                  : '-',
                            ),
                            _infoRow(
                              'Catatan Approver',
                              item.catatanApprover ?? '-',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_isPending)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: AppColors.primaryBackgroundLight,
                  border: Border(
                    top: BorderSide(color: AppColors.secondaryBackgroundLight),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed:
                              _isSubmitting ? null : () => _submit('DITOLAK'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.errorLight,
                            side: const BorderSide(color: AppColors.errorLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.errorLight,
                                    ),
                                  )
                                  : Text(
                                    'Tolak',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: AppColors.errorLight,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              _isSubmitting
                                  ? null
                                  : () => _submit('DISETUJUI'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            disabledBackgroundColor: AppColors.primaryLight
                                .withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    'Setujui',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
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
