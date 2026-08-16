import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final num newNum = num.parse(cleanText);
    final formattedText = _formatter.format(newNum);
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

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

  TipePengajuan? _selectedTipe;

  final _jumlahController = TextEditingController();
  final _dateController = TextEditingController();
  final _catatanController = TextEditingController();
  DateTime? _selectedDate;
  int? _pAnggotaId;

  final int _pJenisTabunganId = 3;
  final List<XFile> _buktiTransferFiles = [];

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

  Future<void> _pickBuktiTransfer() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return;

      final picked =
          result.files
              .where((f) => f.path != null)
              .map((f) => XFile(f.path!, name: f.name))
              .toList();

      if (picked.isEmpty) return;
      setState(() => _buktiTransferFiles.addAll(picked));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih file: $e'),
          backgroundColor: AppColors.errorLight,
        ),
      );
    }
  }

  void _removeBuktiTransfer(int index) {
    setState(() => _buktiTransferFiles.removeAt(index));
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

    if (_selectedTipe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tipe pengajuan terlebih dahulu.'),
          backgroundColor: AppColors.errorLight,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_selectedTipe == TipePengajuan.penyertaan &&
          _buktiTransferFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bukti transfer wajib diunggah.'),
            backgroundColor: AppColors.errorLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        if (_selectedTipe == TipePengajuan.penyertaan) {
          await _apiService.submitPenyertaan(
            pAnggotaId: _pAnggotaId!,
            pJenisTabunganId: _pJenisTabunganId,
            jumlah: int.parse(_jumlahController.text.replaceAll('.', '')),
            tanggalPenyertaan: DateFormat('yyyy/MM/dd').format(_selectedDate!),
            keterangan: _catatanController.text,
            buktiTransfer: _buktiTransferFiles,
          );
        } else {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.errorLight,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: AppTheme.textThemeLight.labelMedium?.copyWith(
          color: AppColors.secondaryTextLight,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _TypeChip(
            label: 'Setoran Langsung',
            icon: LucideIcons.coins,
            selected: _selectedTipe == TipePengajuan.penyertaan,
            onTap: () {
              setState(() {
                _selectedTipe = TipePengajuan.penyertaan;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeChip(
            label: 'Perubahan',
            icon: LucideIcons.refreshCw,
            selected: _selectedTipe == TipePengajuan.penambahan,
            onTap: () {
              setState(() {
                _selectedTipe = TipePengajuan.penambahan;
                _buktiTransferFiles.clear();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBuktiTransferPicker() {
    final textTheme = AppTheme.textThemeLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Bukti Transfer'),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _pickBuktiTransfer,
            borderRadius: BorderRadius.circular(14),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: AppColors.primaryLight.withOpacity(0.45),
                radius: 14,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.upload,
                        size: 22,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _buktiTransferFiles.isEmpty
                          ? 'Ketuk untuk unggah bukti'
                          : 'Tambah file lain',
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryTextLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG, PNG, atau PDF',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryTextLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_buktiTransferFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...List.generate(_buktiTransferFiles.length, (index) {
            final file = _buktiTransferFiles[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.fileCheck2,
                      size: 18,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryTextLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed:
                          _isLoading ? null : () => _removeBuktiTransfer(index),
                      icon: const Icon(LucideIcons.x, size: 16),
                      color: AppColors.secondaryTextLight,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildDynamicFields() {
    final isSetoran = _selectedTipe == TipePengajuan.penyertaan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _jumlahController,
          keyboardType: TextInputType.number,
          style: AppTheme.textThemeLight.bodyMedium?.copyWith(
            color: AppColors.primaryTextLight,
            fontWeight: FontWeight.w600,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(),
          ],
          decoration: _inputDecoration(
            label: isSetoran ? 'Jumlah Setoran' : 'Nilai Baru Penyertaan',
            hint: '0',
            prefixText: 'Rp ',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nilai tidak boleh kosong';
            }
            if (int.tryParse(value.replaceAll('.', '')) == null) {
              return 'Format angka tidak valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dateController,
          readOnly: true,
          onTap: () => _selectDate(context),
          style: AppTheme.textThemeLight.bodyMedium?.copyWith(
            color: AppColors.primaryTextLight,
          ),
          decoration: _inputDecoration(
            label: isSetoran ? 'Tanggal Setoran' : 'Berlaku Mulai Tanggal',
            hint: 'Pilih tanggal',
            suffixIcon: const Icon(
              LucideIcons.calendar,
              size: 18,
              color: AppColors.secondaryTextLight,
            ),
          ),
          validator:
              (value) =>
                  (value == null || value.isEmpty)
                      ? 'Tanggal tidak boleh kosong'
                      : null,
        ),
        if (isSetoran) ...[
          const SizedBox(height: 24),
          _buildBuktiTransferPicker(),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _catatanController,
          maxLines: 3,
          style: AppTheme.textThemeLight.bodyMedium?.copyWith(
            color: AppColors.primaryTextLight,
          ),
          decoration: _inputDecoration(
            label: isSetoran ? 'Keterangan (opsional)' : 'Catatan (opsional)',
            hint: 'Tambahkan catatan jika perlu',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTheme.textThemeLight;

    return Scaffold(
      backgroundColor: AppColors.primaryBackgroundLight,
      appBar: AppBar(
        title: Text(
          'Form Pengajuan',
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.primaryTextLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryBackgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.primaryTextLight,
        centerTitle: false,
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
                    Text(
                      'Ajukan penyertaan',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTextLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pilih tipe pengajuan, lalu lengkapi data yang dibutuhkan.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryTextLight,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Tipe Pengajuan'),
                    _buildTypeSelector(),
                    const SizedBox(height: 28),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axisAlignment: -1,
                            child: child,
                          ),
                        );
                      },
                      child:
                          _selectedTipe == null
                              ? const SizedBox.shrink(key: ValueKey('empty'))
                              : KeyedSubtree(
                                key: ValueKey(_selectedTipe),
                                child: _buildDynamicFields(),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.primaryBackgroundLight,
                border: Border(
                  top: BorderSide(
                    color: AppColors.secondaryBackgroundLight,
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryLight
                        .withOpacity(0.45),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed:
                      (_isLoading ||
                              _pAnggotaId == null ||
                              _selectedTipe == null)
                          ? null
                          : _submitForm,
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                          : Text(
                            'Kirim Pengajuan',
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color:
                selected
                    ? AppColors.primaryLight.withOpacity(0.1)
                    : AppColors.secondaryBackgroundLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  selected
                      ? AppColors.primaryLight
                      : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color:
                    selected
                        ? AppColors.primaryLight
                        : AppColors.secondaryTextLight,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTheme.textThemeLight.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      selected
                          ? AppColors.primaryLight
                          : AppColors.secondaryTextLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke;

    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            Radius.circular(radius),
          ),
        );

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
