// lib/screens/approval_pinjaman_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kkba_mobile/model/pinjaman_list.dart';
import 'package:kkba_mobile/model/pinjaman_preview.dart';
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/theme.dart';

class ApprovalPinjamanScreen extends StatefulWidget {
  final int tPinjamanId;

  const ApprovalPinjamanScreen({super.key, required this.tPinjamanId});

  @override
  _ApprovalPinjamanScreenState createState() => _ApprovalPinjamanScreenState();
}

class _ApprovalPinjamanScreenState extends State<ApprovalPinjamanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Controllers
  final _jumlahDisetujuiController = TextEditingController();
  final _tenorController = TextEditingController();
  final _marginController = TextEditingController();
  final _biayaAdminController = TextEditingController();
  final _catatanController = TextEditingController();

  // State
  PinjamanPreviewDetail? _pinjamanData;
  List<MasterStatusPengajuanSimpleModel> _statusOptions = [];
  int? _selectedStatusId;
  DateTime? _tglPencairan;
  DateTime? _tglPelunasan;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  int _marginRp = 0;
  int _biayaAdminRp = 0;
  int _totalPlusMargin = 0;
  int _estimasiCicilan = 0;
  final _currencyFormatter = NumberFormat.decimalPattern('id_ID');

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _jumlahDisetujuiController.addListener(_recalculatePreview);
    _tenorController.addListener(_recalculatePreview);
    _marginController.addListener(_recalculatePreview);
  }

  @override
  void dispose() {
    // BARU: Hapus listener untuk mencegah memory leak
    _jumlahDisetujuiController.removeListener(_recalculatePreview);
    _tenorController.removeListener(_recalculatePreview);
    _marginController.removeListener(_recalculatePreview);

    _jumlahDisetujuiController.dispose();
    _tenorController.dispose();
    _marginController.dispose();
    _biayaAdminController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final previewResponse = await _apiService.getPinjamanPreview(
        widget.tPinjamanId,
      );
      final statusResponse = await ApiService.getMasterStatusPengajuan();

      if (mounted) {
        setState(() {
          _pinjamanData = previewResponse.data;
          _statusOptions = statusResponse;

          // Isi form dengan data dari API
          _jumlahDisetujuiController.text = (_pinjamanData?.riJumlahPinjaman ??
                  _pinjamanData?.raJumlahPinjaman ??
                  0)
              .toStringAsFixed(0);
          _tenorController.text = _pinjamanData?.tenor.toString() ?? '0';
          _marginController.text = _pinjamanData?.margin?.toString() ?? '0.0';
          _biayaAdminController.text =
              _pinjamanData?.biayaAdmin?.toString() ?? '0.0';
          _catatanController.text = _pinjamanData?.remarks ?? '';
          _selectedStatusId = _pinjamanData?.pStatusPengajuanId;

          if (_pinjamanData?.tglPencairan != null) {
            _tglPencairan = DateTime.tryParse(_pinjamanData!.tglPencairan!);
          }
          if (_pinjamanData?.tglPelunasan != null) {
            _tglPelunasan = DateTime.tryParse(_pinjamanData!.tglPelunasan!);
          }
          _isLoading = false;
          _recalculatePreview();
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
    }
  }

  void _recalculatePreview() {
    final double jumlah =
        double.tryParse(_jumlahDisetujuiController.text.replaceAll('.', '')) ??
        0.0;
    final double marginPercent = double.tryParse(_marginController.text) ?? 0.0;
    final double biayaAdminPercent =
        double.tryParse(_biayaAdminController.text) ?? 0.0;
    final int tenor = int.tryParse(_tenorController.text) ?? 1;

    // Tetap lakukan perhitungan dalam double untuk akurasi
    final double calculatedMarginRp = (marginPercent / 100) * jumlah;
    final double calculatedBiayaAdminRp = (biayaAdminPercent / 100) * jumlah;
    final double newTotalPlusMargin =
        jumlah + calculatedMarginRp + _biayaAdminRp;
    final double newEstimasiCicilan =
        tenor > 0 ? newTotalPlusMargin / tenor : 0;

    setState(() {
      // Bulatkan hasil akhir dan simpan sebagai integer
      _marginRp = calculatedMarginRp.round();
      _biayaAdminRp = calculatedBiayaAdminRp.round();
      _totalPlusMargin = newTotalPlusMargin.round();
      _estimasiCicilan = newEstimasiCicilan.round();
    });
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isPencairan,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          (isPencairan ? _tglPencairan : _tglPelunasan) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isPencairan)
          _tglPencairan = picked;
        else
          _tglPelunasan = picked;
      });
    }
  }

  void _submitApproval() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final jumlahDisetujui =
          double.tryParse(_jumlahDisetujuiController.text) ?? 0;
      final tenor = int.tryParse(_tenorController.text) ?? 0;
      final margin = double.tryParse(_marginController.text) ?? 0;
      final biayaAdmin = double.tryParse(_biayaAdminController.text) ?? 0;
      final catatanValue =
          _catatanController.text.trim().isNotEmpty
              ? _catatanController.text.trim()
              : null;

      await _apiService.submitApproval(
        tPinjamanId: widget.tPinjamanId,
        jumlahDisetujui: jumlahDisetujui,
        tenor: tenor,
        margin: margin,
        biayaAdmin: biayaAdmin,

        statusId: _selectedStatusId!,
        catatan: catatanValue,
        tglPencairan:
            _tglPencairan != null
                ? DateFormat('yyyy-MM-dd').format(_tglPencairan!)
                : null,
        tglPelunasan:
            _tglPelunasan != null
                ? DateFormat('yyyy-MM-dd').format(_tglPelunasan!)
                : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data approval berhasil disimpan!'),
            backgroundColor: AppColors.successLight,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Approval Pinjaman"),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Error: $_errorMessage"),
                ),
              )
              : _buildForm(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: _isSaving ? SizedBox.shrink() : Icon(Icons.save),
          onPressed: _isSaving ? null : _submitApproval,
          label:
              _isSaving
                  ? CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                  : Text("Save Data"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextFormField(
              controller: _jumlahDisetujuiController,
              label: 'Jumlah Pinjaman yang Disetujui',
              prefix: 'Rp. ',
              keyboardType: TextInputType.number,
              isRequired: true,
            ),
            _buildTextFormField(
              controller: _tenorController,
              label: 'Tenor Disetujui',
              suffix: 'Bulan',
              keyboardType: TextInputType.number,
              isRequired: true,
            ),
            _buildTextFormField(
              controller: _marginController,
              label: 'Margin (%)',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              isRequired: true,
            ),

            // --- BAGIAN PERHITUNGAN PREVIEW ---
            const Divider(height: 32),
            _buildCalculationRow(
              'Margin (Rp)',
              'Rp. ${_currencyFormatter.format(_marginRp)}',
            ),
            _buildCalculationRow(
              'Biaya Admin (Rp)',
              'Rp. ${_currencyFormatter.format(_biayaAdminRp)}',
            ),
            _buildCalculationRow(
              'Total Jumlah Disetujui + Margin',
              'Rp. ${_currencyFormatter.format(_totalPlusMargin)}',
            ),
            _buildCalculationRow(
              'Estimasi cicilan per Bulan',
              'Rp. ${_currencyFormatter.format(_estimasiCicilan)}',
              isHighlight: true,
            ),
            const Divider(height: 32),

            // --- AKHIR BAGIAN PERHITUNGAN ---
            _buildTextFormField(
              controller: _biayaAdminController,
              label: 'Biaya Admin (%)',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              isRequired: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedStatusId,
              items:
                  _statusOptions
                      .map(
                        (status) => DropdownMenuItem<int>(
                          value: status.pStatusPengajuanId,
                          child: Text(status.nama ?? 'N/A'),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _selectedStatusId = value),
              decoration: const InputDecoration(
                labelText: 'Status Pinjaman',
                border: OutlineInputBorder(),
              ),
              validator:
                  (value) => value == null ? 'Status harus dipilih' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _catatanController,
              label: 'Catatan',
              maxLines: 3,
              isRequired: false,
            ),
            const SizedBox(height: 16),
            _buildDatePickerField(
              context,
              label: 'Tanggal Pencairan',
              selectedDate: _tglPencairan,
              onTap: () => _selectDate(context, isPencairan: true),
            ),
            const SizedBox(height: 16),
            _buildDatePickerField(
              context,
              label: 'Tanggal Pelunasan',
              selectedDate: _tglPelunasan,
              onTap: () => _selectDate(context, isPencairan: false),
            ),
          ],
        ),
      ),
    );
  }

  // BARU: Helper widget untuk baris kalkulasi
  Widget _buildCalculationRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 15, color: AppColors.secondaryTextLight),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color:
                  isHighlight
                      ? AppColors.primaryLight
                      : AppColors.primaryTextLight,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    String? suffix,
    bool isRequired = false, // Parameter ini sekarang akan digunakan
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          suffixText: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
        // PERBAIKAN LOGIKA VALIDATOR
        validator: (value) {
          // Hanya validasi jika 'isRequired' adalah true
          if (isRequired) {
            if (value == null || value.isEmpty) {
              return '$label tidak boleh kosong';
            }
          }
          // Jika isRequired false, atau jika true tapi field terisi, maka kembalikan null (valid)
          return null;
        },
      ),
    );
  }

  Widget _buildDatePickerField(
    BuildContext context, {
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              selectedDate != null
                  ? DateFormat('dd/MM/yyyy').format(selectedDate)
                  : 'dd/mm/yyyy',
              style: TextStyle(fontSize: 16),
            ),
            Icon(Icons.calendar_today, color: AppColors.primaryLight),
          ],
        ),
      ),
    );
  }
}
