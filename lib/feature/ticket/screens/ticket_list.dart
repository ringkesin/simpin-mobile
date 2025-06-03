// ticket_list_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

// Sesuaikan path import
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/model/ticket_response.dart';
import './create_ticket.dart';
import 'package:kkba_mobile/theme.dart';
// Import halaman chat baru
import './chat_page.dart'; // GANTI DENGAN PATH YANG BENAR

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  final ApiService _apiService = ApiService();
  List<TicketListItemModel> _tickets = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final int _perPage = 10;
  bool _hasMore = true;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();

  // Variabel untuk menyimpan ID pengguna yang sedang login
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Panggil _loadCurrentUserId untuk memuat ID pengguna saat halaman diinisialisasi
    _loadCurrentUserId().then((_) {
      // Setelah userId dimuat (atau gagal dimuat), fetch tiket awal
      // Ini memastikan _currentUserId tersedia sebelum fetch pertama jika diperlukan untuk filter awal
      // atau setidaknya sudah di-attempt untuk dimuat sebelum navigasi ke chat.
      _fetchTickets(isRefresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchTickets();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Fungsi untuk memuat userId dari SharedPreferences
  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        // Ganti 'userId' dengan key yang Anda gunakan saat menyimpan ID pengguna
        _currentUserId = prefs.getInt('userId');
        print("Current User ID loaded in TicketListPage: $_currentUserId");

        // Jika Anda ingin userId = 1 adalah admin, Anda bisa cek di sini
        // atau biarkan ChatPage/ChatMessageModel yang menanganinya berdasarkan created_by
        if (_currentUserId == 1) {
          print("User is Admin (ID: $_currentUserId)");
        } else {
          print("User is NOT Admin (ID: $_currentUserId)");
        }
      });
    }
  }

  Future<void> _fetchTickets({
    bool isRefresh = false,
    TicketListFilterPayload? filter,
  }) async {
    if (_isLoading && !isRefresh) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _currentPage = 1;
        _tickets = [];
        _hasMore = true;
        _errorMessage = null;
      }
    });

    try {
      final response = await _apiService.getTicketList(
        page: _currentPage,
        perpage: _perPage,
        filter: filter,
      );
      if (mounted) {
        if (response.success) {
          setState(() {
            _tickets.addAll(response.data);
            if (response.data.isNotEmpty) {
              _currentPage++;
            }
            _hasMore = response.data.length == _perPage;
            if (isRefresh && response.data.isEmpty) {
              _errorMessage = "Tidak ada tiket ditemukan.";
            }
          });
        } else {
          setState(() {
            _errorMessage = response.message;
            _hasMore = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat tiket: ${response.message}'),
              backgroundColor: AppColors.errorLight,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
          _hasMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $_errorMessage'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToCreateTicket() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTicketPage()),
    );
    if (result == true) {
      _fetchTickets(isRefresh: true);
    }
  }

  // Navigasi ke halaman chat
  void _navigateToChatPage(TicketListItemModel ticket) {
    if (_currentUserId == null) {
      // Handle jika _currentUserId masih null (belum selesai dimuat atau tidak ada)
      // Anda bisa menampilkan pesan atau mencoba memuatnya lagi.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ID Pengguna belum termuat. Mohon tunggu atau coba lagi.',
          ),
        ),
      );
      // Coba muat ulang jika belum ada, mungkin ada race condition saat init
      if (!_isLoading) _loadCurrentUserId();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatPage(
              tChatId: ticket.tChatId.trim(),
              ticketCode: ticket.ticketCode,
              currentUserId:
                  _currentUserId!, // Sekarang _currentUserId sudah pasti non-null di sini
            ),
      ),
    );
  }

  Widget _buildTicketItem(TicketListItemModel ticket) {
    Color statusColor;
    String statusText = ticket.statusDisplay;

    switch (ticket.status) {
      case 0:
        statusColor = AppColors.warningLight;
        break;
      case 1:
        statusColor = AppColors.infoLight;
        break;
      case 2:
        statusColor = AppColors.successLight;
        break;
      case 3:
        statusColor = AppColors.secondaryTextLight;
        break;
      default:
        statusColor = AppColors.secondaryTextLight;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 3.0,
      shadowColor: AppColors.primaryLight.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: AppColors.secondaryLight,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          _navigateToChatPage(ticket);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      ticket.ticketCode,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: AppColors.primaryTextLight,
                      ),
                    ),
                  ),
                  if (ticket.countNotif > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${ticket.countNotif} Baru',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ticket.subject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.secondaryTextLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.flag_outlined, size: 16, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                  if (ticket.createdAt != null) // Menampilkan tanggal jika ada
                    Text(
                      DateFormat(
                        'dd MMM yy, HH:mm',
                        'id_ID',
                      ).format(ticket.createdAt!.toLocal()),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.secondaryTextLight.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 1.0,
        title: Text(
          'Daftar Tiket',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchTickets(isRefresh: true),
        color: AppColors.primaryLight,
        child: Column(
          children: [
            Expanded(
              child:
                  (_isLoading && _tickets.isEmpty && _errorMessage == null)
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryLight,
                        ),
                      )
                      : (_errorMessage != null && _tickets.isEmpty)
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.errorLight,
                                size: 50,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Gagal Memuat Data',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryTextLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.secondaryTextLight,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Coba Lagi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryLight,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () => _fetchTickets(isRefresh: true),
                              ),
                            ],
                          ),
                        ),
                      )
                      : _tickets.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 60,
                              color: AppColors.secondaryTextLight.withOpacity(
                                0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada tiket.',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                color: AppColors.secondaryTextLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ketuk tombol + untuk membuat tiket baru.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.secondaryTextLight.withOpacity(
                                  0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
                        itemCount:
                            _tickets.length +
                            (_hasMore && _tickets.isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _tickets.length) {
                            if (_isLoading) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryLight,
                                    strokeWidth: 3,
                                  ),
                                ),
                              );
                            } else if (_hasMore) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryLight,
                                      side: const BorderSide(
                                        color: AppColors.primaryLight,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _fetchTickets(),
                                    child: Text(
                                      'Muat Tiket Lainnya',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          }
                          final ticket = _tickets[index];
                          return _buildTicketItem(ticket);
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateTicket,
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_outlined, size: 22),
        label: Text(
          'Buat Tiket',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
