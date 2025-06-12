// ticket_list_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Import paket slidable

import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/model/ticket_response.dart';
import './create_ticket.dart';
import 'package:kkba_mobile/theme.dart';
import './chat_page.dart';

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
  final int _perPage = 15; // Tambah item per halaman untuk scrolling
  bool _hasMore = true;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();
  int? _currentUserId;
  String? _userRole; // State untuk menyimpan role pengguna

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetchTickets(); // Memuat role dan user ID

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchTickets();
      }
    });
  }

  Future<void> _loadUserDataAndFetchTickets() async {
    await _loadUserData();
    _fetchTickets(isRefresh: true);
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _currentUserId = prefs.getInt('userId');
          _userRole = prefs.getString(
            'role',
          ); // Ambil role dari SharedPreferences
          print("Loaded User ID: $_currentUserId, Role: $_userRole");
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data pengguna: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        setState(() {
          _tickets.addAll(response.data);
          _currentPage++;
          _hasMore = response.data.length == _perPage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
          _hasMore = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _closeTicket(String tChatId) async {
    // Tampilkan dialog konfirmasi
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menutup tiket ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Ya, Tutup',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return; // Jika pengguna membatalkan

    try {
      final response = await _apiService.closeTicket(tChatId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Tiket berhasil ditutup.'),
            backgroundColor: AppColors.successLight,
          ),
        );
        _fetchTickets(isRefresh: true); // Muat ulang daftar tiket
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
    }
  }

  // ... (Sisa fungsi seperti _navigateToCreateTicket, _navigateToChatPage tidak berubah)
  Future<void> _navigateToCreateTicket() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTicketPage()),
    );
    if (result == true) {
      _fetchTickets(isRefresh: true);
    }
  }

  void _navigateToChatPage(TicketListItemModel ticket) {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Pengguna belum termuat. Coba muat ulang halaman.'),
          backgroundColor: AppColors.warningLight,
        ),
      );
      _loadUserDataAndFetchTickets();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatPage(
              tChatId: ticket.tChatId.trim(),
              ticketCode: ticket.ticketCode,
              ticketSubject: ticket.subject,
              currentUserId: _currentUserId!,
              ticketStatus: ticket.status, // Kirim status tiket ke halaman chat
            ),
      ),
    );
  }

  Widget _buildTicketItem(TicketListItemModel ticket) {
    // 1. Logika untuk menentukan warna dan ikon berdasarkan status
    Color statusColor;
    IconData statusIcon;

    switch (ticket.status) {
      case 0: // Tiket Baru (Aktif)
        statusColor =
            AppColors.primaryLight; // Biru untuk status aktif/informasi
        statusIcon = Icons.chat_bubble_outline; // Ikon untuk chat/tiket baru
        break;
      case 1: // Ticket Close (Tidak Aktif)
        statusColor =
            AppColors.primaryDark; // Abu-abu untuk status selesai/ditutup
        statusIcon =
            Icons.check_circle_outline; // Ikon untuk yang sudah selesai
        break;
      default: // Fallback jika ada status lain yang tidak terduga
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    // 2. Logika untuk mengaktifkan/menonaktifkan fitur slide
    // Fitur hanya aktif jika role adalah 'mobile_admin' DAN status tiket belum selesai/ditutup.
    final bool isSlidable = _userRole == 'mobile_admin' && ticket.status < 2;

    return Slidable(
      key: ValueKey(ticket.tChatId),
      enabled: isSlidable, // Gunakan variabel isSlidable di sini
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _closeTicket(ticket.tChatId),
            backgroundColor:
                AppColors.errorLight, // Warna lebih cocok untuk menutup
            foregroundColor: Colors.white,
            icon: Icons.archive_rounded,
            label: 'Close',
          ),
        ],
      ),
      child: Material(
        color: AppColors.secondaryBackgroundLight,
        child: InkWell(
          onTap: () => _navigateToChatPage(ticket),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(
                    statusIcon, // Gunakan ikon status dinamis
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.ticketCode,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.primaryTextLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.secondaryTextLight,
                        ),
                      ),
                      const SizedBox(height: 8), // Spasi sebelum status
                      // 3. Menampilkan statusDisplay di sini
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            ticket.statusDisplay,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (ticket.createdAt != null)
                      Text(
                        DateFormat(
                          'HH:mm',
                          'id_ID',
                        ).format(ticket.createdAt!.toLocal()),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color:
                              ticket.countNotif > 0
                                  ? AppColors.successLight
                                  : AppColors.secondaryTextLight,
                          fontWeight:
                              ticket.countNotif > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (ticket.countNotif > 0)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${ticket.countNotif}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 22),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBackgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0, // Membuat AppBar seamless dengan list
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
        onRefresh: () => _loadUserDataAndFetchTickets(),
        color: AppColors.primaryLight,
        child:
            (_isLoading && _tickets.isEmpty)
                ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryLight,
                  ),
                )
                : (_errorMessage != null && _tickets.isEmpty)
                ? _buildErrorWidget() // Widget error terpisah
                : (_tickets.isEmpty)
                ? _buildEmptyWidget() // Widget kosong terpisah
                : _buildTicketListView(),
      ),
      floatingActionButton: FloatingActionButton(
        // Diubah ke FAB biasa
        onPressed: _navigateToCreateTicket,
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 4.0,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  // Widget untuk daftar tiket (ListView.separated)
  Widget _buildTicketListView() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80.0),
      itemCount: _tickets.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _tickets.length) {
          final ticket = _tickets[index];
          return _buildTicketItem(ticket);
        } else {
          return _buildLoader();
        }
      },
      separatorBuilder:
          (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.withOpacity(0.15),
            indent: 88, // Separator mulai setelah avatar
            endIndent: 16,
          ),
    );
  }

  // Widget untuk loader di bagian bawah
  Widget _buildLoader() {
    return _isLoading
        ? const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: AppColors.primaryLight),
          ),
        )
        : const SizedBox.shrink();
  }

  // Widget untuk tampilan kosong
  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 60,
            color: AppColors.secondaryTextLight.withOpacity(0.4),
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
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.secondaryTextLight.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk tampilan error
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.errorLight, size: 50),
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
    );
  }
}
