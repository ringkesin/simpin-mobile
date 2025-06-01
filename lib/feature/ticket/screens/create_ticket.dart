// create_ticket_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// GANTI DENGAN PATH YANG BENAR KE FILE ANDA
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/model/ticket_response.dart';
import 'package:kkba_mobile/model/pinjaman_list.dart';
import 'package:kkba_mobile/theme.dart'; // Import AppColors Anda

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final ApiService _apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _manualTransactionIdController =
      TextEditingController();

  List<ChatReferenceTableItem> _chatReferences = [];
  ChatReferenceTableItem? _selectedChatReference;

  List<PinjamanDetailModel> _pinjamanList = [];
  PinjamanDetailModel? _selectedPinjaman;

  bool _isLoadingReferences = false;
  bool _isLoadingPinjaman = false;
  bool _isSubmitting = false;
  bool _isPinjamanType = false;

  @override
  void initState() {
    super.initState();
    _fetchChatReferences();
  }

  Future<void> _fetchChatReferences() async {
    setState(() {
      _isLoadingReferences = true;
      _selectedChatReference = null;
      _pinjamanList = [];
      _selectedPinjaman = null;
      _isPinjamanType = false;
    });
    try {
      final references = await _apiService.getChatReferenceTable();
      setState(() {
        _chatReferences = references;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat referensi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReferences = false;
        });
      }
    }
  }

  Future<void> _fetchPinjamanList() async {
    if (_selectedChatReference == null) return;

    setState(() {
      _isLoadingPinjaman = true;
      _pinjamanList = [];
      _selectedPinjaman = null;
    });
    try {
      final pinjamanListResponse = await ApiService.getListPengajuanPinjaman(
        page: 1,
      );

      if (pinjamanListResponse.success && pinjamanListResponse.data != null) {
        setState(() {
          _pinjamanList = pinjamanListResponse.data!.data;
        });
      } else {
        throw Exception(
          pinjamanListResponse.message ?? 'Gagal memuat daftar pinjaman.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat daftar pinjaman: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPinjaman = false;
        });
      }
    }
  }

  void _onChatReferenceChanged(ChatReferenceTableItem? newValue) {
    setState(() {
      _selectedChatReference = newValue;
      _selectedPinjaman = null;
      _pinjamanList = [];
      _manualTransactionIdController.clear();

      if (newValue != null &&
          newValue.referenceTableKeyName == 't_pinjaman_id') {
        _isPinjamanType = true;
        _fetchPinjamanList();
      } else {
        _isPinjamanType = false;
      }
    });
  }

  void _onPinjamanChanged(PinjamanDetailModel? newValue) {
    setState(() {
      _selectedPinjaman = newValue;
    });
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedChatReference == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih jenis referensi.')),
      );
      return;
    }

    int? transactionId;
    if (_isPinjamanType) {
      if (_selectedPinjaman == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih transaksi pinjaman.')),
        );
        return;
      }
      transactionId = _selectedPinjaman!.tPinjamanId;
    } else {
      if (_manualTransactionIdController.text.isNotEmpty) {
        transactionId = int.tryParse(_manualTransactionIdController.text);
        if (transactionId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID Transaksi manual tidak valid.')),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan masukkan ID Transaksi.')),
        );
        return;
      }
    }

    if (transactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Transaksi tidak dapat ditentukan.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _apiService.createTicket(
        pChatReferenceTableId: _selectedChatReference!.pChatReferenceTableId,
        transactionId: transactionId,
        subject: _subjectController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor:
                response.success
                    ? AppColors.successLight
                    : AppColors.errorLight,
          ),
        );
        if (response.success) {
          _formKey.currentState?.reset();
          _subjectController.clear();
          _manualTransactionIdController.clear();
          setState(() {
            _selectedChatReference = null;
            _selectedPinjaman = null;
            _pinjamanList = [];
            _isPinjamanType = false;
          });
          if (mounted) Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat tiket: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _manualTransactionIdController.dispose();
    super.dispose();
  }

  // Tidak perlu _buildCustomHeader terpisah jika seluruh background sama
  // Widget _buildCustomHeader(BuildContext context) { ... }

  InputDecoration _customInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText ?? 'Pilih atau masukkan $labelText',
      labelStyle: GoogleFonts.inter(
        color: AppColors.secondaryTextLight,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.inter(
        color: AppColors.secondaryTextLight.withOpacity(0.7),
        fontSize: 14,
      ),
      prefixIcon:
          prefixIcon != null
              ? Icon(prefixIcon, color: AppColors.primaryLight, size: 20)
              : null,
      filled: true,
      fillColor: AppColors.secondaryBackgroundLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: Colors.grey.shade300.withOpacity(0.5),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
        horizontal: 16.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan tinggi status bar
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      // Seluruh background halaman sekarang menggunakan AppColors.primaryLight
      backgroundColor: AppColors.primaryLight,
      body: SafeArea(
        // Menggunakan SafeArea untuk menghindari notch/status bar
        bottom:
            false, // Tidak perlu safe area di bawah jika tidak ada bottom navigation bar
        child: Column(
          // Menggunakan Column untuk header dan konten
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section (Tombol Kembali dan Judul)
            Padding(
              padding: const EdgeInsets.only(
                top: 8.0,
                left: 8.0,
                right: 16.0,
                bottom: 0,
              ), // Mengurangi padding bottom
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  // const SizedBox(width: 0), // Mengurangi spasi jika perlu
                  Text(
                    'Buat Tiket Baru',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              // Padding untuk subjudul, disesuaikan agar lebih dekat ke judul
              padding: const EdgeInsets.only(
                left: 58.0,
                right: 16.0,
                bottom: 16.0,
                top: 0,
              ),
              child: Text(
                'Lengkapi detail tiket Anda di bawah ini.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),

            // Form Content dalam Card
            Expanded(
              child: Container(
                // Memberi sedikit margin atas untuk memisahkan dari header
                margin: const EdgeInsets.only(top: 8.0),
                decoration: const BoxDecoration(
                  color:
                      AppColors
                          .secondaryBackgroundLight, // Warna latar belakang untuk area di bawah card (jika card tidak full)
                  // atau bisa juga AppColors.primaryBackgroundLight
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(24.0),
                  ),
                ),
                child: ClipRRect(
                  // Untuk memastikan card mengikuti border radius container
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(24.0),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: 0,
                    ), // Card menempel ke atas container
                    child: Padding(
                      // Padding untuk konten di dalam area scroll, di atas Card
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        24.0,
                        16.0,
                        16.0,
                      ),
                      child: Card(
                        elevation:
                            0.0, // Hilangkan shadow Card karena sudah ada di container luar
                        margin: EdgeInsets.zero, // Hilangkan margin Card
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16.0,
                          ), // Sesuaikan radius Card
                        ),
                        color: AppColors.secondaryLight, // Warna card putih
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  "Detail Tiket",
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryTextLight,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Dropdown untuk Chat Reference
                                if (_isLoadingReferences)
                                  const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryLight,
                                    ),
                                  )
                                else
                                  DropdownButtonFormField<
                                    ChatReferenceTableItem
                                  >(
                                    value: _selectedChatReference,
                                    decoration: _customInputDecoration(
                                      labelText: 'Jenis Referensi',
                                      prefixIcon: Icons.category_outlined,
                                    ),
                                    isExpanded: true,
                                    items:
                                        _chatReferences.map((
                                          ChatReferenceTableItem item,
                                        ) {
                                          return DropdownMenuItem<
                                            ChatReferenceTableItem
                                          >(
                                            value: item,
                                            child: Text(
                                              item.customName,
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                color:
                                                    AppColors.primaryTextLight,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: _onChatReferenceChanged,
                                    validator:
                                        (value) =>
                                            value == null
                                                ? 'Jenis referensi harus dipilih'
                                                : null,
                                    icon: const Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: AppColors.secondaryTextLight,
                                    ),
                                    dropdownColor: AppColors.secondaryLight,
                                  ),
                                const SizedBox(height: 16),

                                // Dropdown untuk Pinjaman (jika tipe pinjaman dipilih)
                                if (_isPinjamanType) ...[
                                  if (_isLoadingPinjaman)
                                    const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryLight,
                                      ),
                                    )
                                  else if (_pinjamanList.isNotEmpty)
                                    DropdownButtonFormField<
                                      PinjamanDetailModel
                                    >(
                                      value: _selectedPinjaman,
                                      decoration: _customInputDecoration(
                                        labelText: 'Transaksi Pinjaman',
                                        prefixIcon: Icons.receipt_long_outlined,
                                      ),
                                      isExpanded: true,
                                      items:
                                          _pinjamanList.map((
                                            PinjamanDetailModel item,
                                          ) {
                                            return DropdownMenuItem<
                                              PinjamanDetailModel
                                            >(
                                              value: item,
                                              child: Text(
                                                item.nomorPinjaman ??
                                                    'Pinjaman ID: ${item.tPinjamanId}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 15,
                                                  color:
                                                      AppColors
                                                          .primaryTextLight,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: _onPinjamanChanged,
                                      validator:
                                          (value) =>
                                              _isPinjamanType && value == null
                                                  ? 'Transaksi pinjaman harus dipilih'
                                                  : null,
                                      icon: const Icon(
                                        Icons.arrow_drop_down_rounded,
                                        color: AppColors.secondaryTextLight,
                                      ),
                                      dropdownColor: AppColors.secondaryLight,
                                    )
                                  else if (_selectedChatReference != null &&
                                      !_isLoadingPinjaman)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Text(
                                        'Tidak ada data pinjaman tersedia.',
                                        style: GoogleFonts.inter(
                                          color: AppColors.secondaryTextLight,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                ],

                                // Input manual untuk Transaction ID
                                if (!_isPinjamanType &&
                                    _selectedChatReference != null) ...[
                                  TextFormField(
                                    controller: _manualTransactionIdController,
                                    decoration: _customInputDecoration(
                                      labelText: 'ID Transaksi (Manual)',
                                      prefixIcon:
                                          Icons.confirmation_number_outlined,
                                    ),
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: AppColors.primaryTextLight,
                                    ),
                                    validator: (value) {
                                      if (!_isPinjamanType) {
                                        if (value == null || value.isEmpty) {
                                          return 'ID Transaksi manual harus diisi';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'ID Transaksi harus berupa angka';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Input untuk Subject
                                TextFormField(
                                  controller: _subjectController,
                                  decoration: _customInputDecoration(
                                    labelText: 'Subjek Tiket',
                                    prefixIcon: Icons.subject_outlined,
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    color: AppColors.primaryTextLight,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Subjek tiket harus diisi';
                                    }
                                    return null;
                                  },
                                  maxLines: 3,
                                  minLines: 1,
                                ),
                                const SizedBox(height: 24),

                                // Tombol Submit
                                ElevatedButton(
                                  onPressed:
                                      _isSubmitting ? null : _submitTicket,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryLight,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14.0,
                                    ),
                                    textStyle: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                  ),
                                  child:
                                      _isSubmitting
                                          ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Text('Kirim Tiket'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
