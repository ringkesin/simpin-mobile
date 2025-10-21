import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../service/api_service.dart';
import '../../../theme.dart';

// Helper untuk memformat input angka
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty)
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    final num newNum = num.parse(cleanText);
    String formattedText = _formatter.format(newNum);
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

// Enum untuk membedakan tipe pengajuan
enum TipePengajuan { penyertaan, penambahan }

class PenyertaanUniversalFormPage extends StatefulWidget {
  const PenyertaanUniversalFormPage({Key? key}) : super(key: key);

  @override
  _PenyertaanUniversalFormPageState createState() =>
      _PenyertaanUniversalFormPageState();
}

class _PenyertaanUniversalFormPageState
    extends State<PenyertaanUniversalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  // State untuk dropdown utama
  TipePengajuan? _selectedTipe;

  final _jumlahController = TextEditingController();
  final _dateController = TextEditingController();
  final _catatanController = TextEditingController();
  DateTime? _selectedDate;
  int? _pAnggotaId;

  // ID Jenis Tabungan yang sudah ditentukan
  final int _pJenisTabunganId = 3;

  @override
  void initState() {
    super.initState();
    _loadAnggotaId();
  }

  Future<void> _loadAnggotaId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('p_anggota_id');
    if (id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID Anggota tidak valid.'),
            backgroundColor: AppColors.errorLight,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      setState(() => _pAnggotaId = id);
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _dateController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat(
          'd MMMM yyyy',
          'id_ID',
        ).format(picked);
      });
    }
  }

  void _submitForm() async {
    FocusScope.of(context).unfocus();
    if (_pAnggotaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Anggota tidak ditemukan.'),
          backgroundColor: AppColors.errorLight,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Logika dinamis untuk memanggil API yang benar
        if (_selectedTipe == TipePengajuan.penyertaan) {
          // Panggil API Penyertaan Awal
          await _apiService.submitPenyertaan(
            pAnggotaId: _pAnggotaId!,
            pJenisTabunganId: _pJenisTabunganId,
            jumlah: int.parse(_jumlahController.text.replaceAll('.', '')),
            tanggalPenyertaan: DateFormat('yyyy/MM/dd').format(_selectedDate!),
          );
        } else {
          // Panggil API Perubahan/Penambahan
          await _apiService.submitPerubahanPenyertaan(
            pAnggotaId: _pAnggotaId!,
            pJenisTabunganId: _pJenisTabunganId,
            nilaiBaru: int.parse(_jumlahController.text.replaceAll('.', '')),
            validFrom: DateFormat('yyyy/MM/dd').format(_selectedDate!),
            catatanUser: _catatanController.text,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengajuan berhasil disubmit!'),
              backgroundColor: AppColors.successLight,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.errorLight,
              behavior: SnackBarBehavior.floating,
            ),
          );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildFormFieldGroup({required String label, required Widget child}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextLight,
            ),
          ),
          const SizedBox(height: 8),
          child,
          const SizedBox(height: 24),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Form Pengajuan',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        backgroundColor: AppColors.primaryBackgroundLight,
        elevation: 0,
        foregroundColor: AppColors.primaryTextLight,
      ),
      backgroundColor: AppColors.primaryBackgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- DROPDOWN UTAMA UNTUK MEMILIH TIPE ---
              _buildFormFieldGroup(
                label: 'Tipe Pengajuan',
                child: DropdownButtonFormField<TipePengajuan>(
                  value: _selectedTipe,
                  decoration: const InputDecoration(
                    hintText: 'Pilih tipe pengajuan',
                    prefixIcon: Icon(LucideIcons.filePlus, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: TipePengajuan.penyertaan,
                      child: Text('Penyertaan Awal'),
                    ),
                    DropdownMenuItem(
                      value: TipePengajuan.penambahan,
                      child: Text('Penambahan / Perubahan'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedTipe = value),
                  validator:
                      (value) => value == null ? 'Pilih tipe pengajuan' : null,
                ),
              ),

              // --- FORM DINAMIS MUNCUL SETELAH TIPE DIPILIH ---
              if (_selectedTipe != null) ...[
                _buildFormFieldGroup(
                  // Label dinamis sesuai pilihan
                  label:
                      _selectedTipe == TipePengajuan.penyertaan
                          ? 'Jumlah Penyertaan'
                          : 'Nilai Baru Penyertaan',
                  child: TextFormField(
                    controller: _jumlahController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(LucideIcons.wallet, size: 20),
                      prefixText: 'Rp ',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Nilai tidak boleh kosong';
                      if (int.tryParse(value.replaceAll('.', '')) == null)
                        return 'Format angka tidak valid';
                      return null;
                    },
                  ),
                ),

                _buildFormFieldGroup(
                  label:
                      _selectedTipe == TipePengajuan.penyertaan
                          ? 'Tanggal Penyertaan'
                          : 'Berlaku Mulai Tanggal',
                  child: TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    decoration: const InputDecoration(
                      hintText: 'Pilih tanggal',
                      prefixIcon: Icon(LucideIcons.calendar, size: 20),
                    ),
                    validator:
                        (value) =>
                            (value == null || value.isEmpty)
                                ? 'Tanggal tidak boleh kosong'
                                : null,
                  ),
                ),

                // Field catatan hanya muncul untuk tipe penambahan/perubahan
                if (_selectedTipe == TipePengajuan.penambahan)
                  _buildFormFieldGroup(
                    label: 'Catatan (Opsional)',
                    child: TextFormField(
                      controller: _catatanController,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan catatan jika perlu',
                        prefixIcon: Icon(LucideIcons.messageSquare, size: 20),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        (_isLoading || _pAnggotaId == null)
                            ? null
                            : _submitForm,
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                            : const Text('Submit Pengajuan'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
