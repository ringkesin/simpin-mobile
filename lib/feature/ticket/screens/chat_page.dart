// screens/chat_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sesuaikan path import dengan struktur proyek Anda
import 'package:kkba_mobile/service/api_service.dart';
// Pastikan model ini berisi ChatMessageModel dan model lain yang relevan untuk chat
import 'package:kkba_mobile/model/ticket_response.dart';
import 'package:kkba_mobile/theme.dart';

class ChatPage extends StatefulWidget {
  final String tChatId;
  final String ticketCode;
  final String ticketSubject;
  final int ticketStatus; // Tambahkan parameter ini
  final int? currentUserId;

  const ChatPage({
    super.key,
    required this.tChatId,
    required this.ticketCode,
    required this.ticketSubject,
    required this.ticketStatus, // Jadikan required
    this.currentUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ApiService _apiService = ApiService();
  List<ChatMessageModel> _messages = [];
  bool _isLoadingMessages = true;
  bool _isSendingMessage = false;
  String? _errorMessage;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late int _loggedInUserId;

  @override
  void initState() {
    super.initState();
    // Langsung gunakan widget.currentUserId jika sudah ada,
    // atau coba load jika null (sebagai fallback jika halaman ini dibuka langsung misal dari notifikasi)
    if (widget.currentUserId != null && widget.currentUserId != 0) {
      _loggedInUserId = widget.currentUserId!;
      _fetchMessages();
    } else {
      _loadLoggedInUserIdAndFetchMessages();
    }
  }

  Future<void> _loadLoggedInUserIdAndFetchMessages() async {
    await _loadLoggedInUserId();
    if (_loggedInUserId != 0) {
      _fetchMessages();
    } else if (mounted) {
      setState(() {
        _isLoadingMessages = false;
        _errorMessage = "Tidak dapat memuat ID pengguna untuk chat.";
      });
    }
  }

  Future<void> _loadLoggedInUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Ganti 'userId' dengan key yang Anda gunakan saat menyimpan ID pengguna
      final userIdFromPrefs = prefs.getInt('userId');
      if (mounted) {
        setState(() {
          if (userIdFromPrefs != null) {
            _loggedInUserId = userIdFromPrefs;
            print("Loaded Logged In User ID in ChatPage: $_loggedInUserId");
          } else {
            _loggedInUserId = 0; // Default jika tidak ditemukan
            print(
              "Error: Logged in User ID not found in SharedPreferences. Using default 0.",
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Gagal memuat ID pengguna dari SharedPreferences.',
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      print("Error loading logged in user ID: $e");
      if (mounted) {
        setState(() {
          _loggedInUserId = 0; // Fallback
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memuat ID pengguna: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool scrollToBottom = true}) async {
    if (_loggedInUserId == 0 && widget.currentUserId == null) {
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
          _errorMessage = "ID Pengguna tidak valid untuk memuat pesan.";
        });
      }
      return;
    }

    setState(() {
      _isLoadingMessages = true;
      _errorMessage = null;
    });
    try {
      final response = await _apiService.getChatMessages(
        widget.tChatId,
        currentUserId: _loggedInUserId,
      );
      if (mounted) {
        if (response.success) {
          setState(() {
            _messages = response.data;
          });
          if (scrollToBottom && _messages.isNotEmpty) {
            _scrollToBottom();
          }
        } else {
          setState(() {
            _errorMessage = response.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSendingMessage) {
      return;
    }
    if (_loggedInUserId == 0 && widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat mengirim pesan, ID pengguna tidak valid.'),
        ),
      );
      return;
    }
    setState(() {
      _isSendingMessage = true;
    });

    final messageText = _messageController.text.trim();

    try {
      final response = await _apiService.sendChatMessage(
        tChatId: widget.tChatId,
        messageText: messageText,
        currentUserId: _loggedInUserId,
      );
      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _messages.add(response.data!);
            _messageController.clear();
          });
          _scrollToBottom();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengirim pesan: ${response.message}'),
              backgroundColor: AppColors.errorLight,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: ${e.toString()}'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final bool isMe = message.isCurrentUser;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = isMe ? TextAlign.end : TextAlign.start;
    final bgColor =
        isMe ? AppColors.primaryLight : AppColors.secondaryBackgroundLight;
    final textColor = isMe ? Colors.white : AppColors.primaryTextLight;
    final timeColor =
        isMe
            ? Colors.white.withOpacity(0.7)
            : AppColors.secondaryTextLight.withOpacity(0.7);
    final bubbleRadius = BorderRadius.only(
      topLeft: Radius.circular(isMe ? 18.0 : 6.0),
      topRight: Radius.circular(isMe ? 6.0 : 18.0),
      bottomLeft: const Radius.circular(18.0),
      bottomRight: const Radius.circular(18.0),
    );

    String senderDisplayName = "";
    if (!isMe) {
      // Hanya tampilkan nama jika bukan pesan dari pengguna saat ini
      if (message.createdByInfo != null) {
        senderDisplayName =
            message.createdByInfo!.name; // Ambil nama dari objek senderInfo
      } else if (message.createdById == 1) {
        // Fallback jika createdByInfo null tapi createdById adalah 1 (Admin)
        // Ini mungkin terjadi jika API send message mengembalikan ID, bukan objek
        senderDisplayName = "Admin";
      } else {
        // Fallback jika tidak ada info nama sama sekali
        senderDisplayName = "Pengguna ${message.createdById ?? ''}".trim();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (!isMe && senderDisplayName.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: isMe ? 0 : 10,
                right: isMe ? 10 : 0,
                bottom: 3,
              ),
              child: Text(
                senderDisplayName,
                textAlign: textAlign,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextLight,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: bubbleRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              message.messageText,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: EdgeInsets.only(left: isMe ? 0 : 10, right: isMe ? 10 : 0),
            child: Text(
              DateFormat('HH:mm', 'id_ID').format(message.createdAt.toLocal()),
              style: GoogleFonts.inter(fontSize: 10.5, color: timeColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.ticketSubject,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 17,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (widget.ticketCode.isNotEmpty)
              Text(
                widget.ticketCode,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.normal,
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12.5,
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 1.0,
        toolbarHeight: 65,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                (_isLoadingMessages && _messages.isEmpty)
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryLight,
                      ),
                    )
                    : _errorMessage != null && _messages.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.errorLight.withOpacity(0.7),
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppColors.secondaryTextLight,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed:
                                  () => _fetchMessages(scrollToBottom: true),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text("Coba Lagi"),
                            ),
                          ],
                        ),
                      ),
                    )
                    : _messages.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.secondaryTextLight.withOpacity(
                              0.4,
                            ),
                            size: 50,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Mulai percakapan.',
                            style: GoogleFonts.inter(
                              fontSize: 16,
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
                      padding: const EdgeInsets.fromLTRB(
                        12.0,
                        16.0,
                        12.0,
                        16.0,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
          ),

          // **** PERUBAHAN UTAMA DI SINI ****
          // Tampilkan input field atau banner tiket ditutup secara kondisional
          if (widget.ticketStatus == 1)
            _buildTicketClosedBanner() // Tampilkan banner jika status 1 (Close)
          else
            _buildMessageInputField(), // Tampilkan input jika status lain
          // **** AKHIR PERUBAHAN UTAMA ****
        ],
      ),
    );
  }

  // BARU: Widget untuk menampilkan banner bahwa tiket sudah ditutup
  Widget _buildTicketClosedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      width: double.infinity,
      color: AppColors.secondaryBackgroundLight.withOpacity(0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 18,
            color: AppColors.secondaryTextLight,
          ),
          const SizedBox(width: 8),
          Text(
            'Tiket ini telah ditutup.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 8.0, 8.0),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300.withOpacity(0.7),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.primaryTextLight,
              ),
              decoration: InputDecoration(
                hintText: 'Ketik pesan Anda...',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.secondaryTextLight.withOpacity(0.7),
                ),
                filled: true,
                fillColor: AppColors.secondaryBackgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 8.0),
          Material(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(24.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(24.0),
              onTap: _sendMessage,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child:
                    _isSendingMessage
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
