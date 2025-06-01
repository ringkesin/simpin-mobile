// screens/chat_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal dan waktu

// Sesuaikan path import
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/model/ticket_response.dart'; // Untuk ChatMessageModel, dll.
import 'package:kkba_mobile/theme.dart';

class ChatPage extends StatefulWidget {
  final String tChatId;
  final String ticketCode;
  final int currentUserId; // ID pengguna yang sedang login

  const ChatPage({
    super.key,
    required this.tChatId,
    required this.ticketCode,
    required this.currentUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ApiService _apiService = ApiService();
  List<ChatMessageModel> _messages = [];
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;
  String? _errorMessage;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool scrollToBottom = false}) async {
    setState(() {
      _isLoadingMessages = true;
      _errorMessage = null;
    });
    try {
      final response = await _apiService.getChatMessages(
        widget.tChatId,
        currentUserId: widget.currentUserId,
      );
      if (mounted) {
        if (response.success) {
          setState(() {
            _messages = response.data;
          });
          if (scrollToBottom || _messages.isNotEmpty) {
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
    setState(() {
      _isSendingMessage = true;
    });

    final messageText = _messageController.text.trim();

    try {
      final response = await _apiService.sendChatMessage(
        tChatId: widget.tChatId,
        messageText: messageText,
        currentUserId:
            widget.currentUserId, // Kirim ID user agar pesan baru bisa ditandai
      );
      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _messages.add(response.data!); // Tambahkan pesan baru ke list
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
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final bool isMe = message.isCurrentUser; // Menggunakan field isCurrentUser
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor =
        isMe ? AppColors.primaryLight : AppColors.secondaryBackgroundLight;
    final textColor = isMe ? Colors.white : AppColors.primaryTextLight;
    final timeColor = isMe ? Colors.white70 : AppColors.secondaryTextLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMe ? 16.0 : 4.0),
                topRight: Radius.circular(isMe ? 4.0 : 16.0),
                bottomLeft: const Radius.circular(16.0),
                bottomRight: const Radius.circular(16.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              message.messageText,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: isMe ? 0 : 8, right: isMe ? 8 : 0),
            child: Text(
              DateFormat('HH:mm', 'id_ID').format(message.createdAt.toLocal()),
              style: GoogleFonts.inter(fontSize: 11, color: timeColor),
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
        title: Text(
          widget.ticketCode,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 1.0,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoadingMessages
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryLight,
                      ),
                    )
                    : _errorMessage != null
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(color: AppColors.errorLight),
                        ),
                      ),
                    )
                    : _messages.isEmpty
                    ? Center(
                      child: Text(
                        'Belum ada percakapan.',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: AppColors.secondaryTextLight,
                        ),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color:
            AppColors.secondaryLight, // Warna latar belakang input field area
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.primaryTextLight,
              ),
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.secondaryTextLight.withOpacity(0.8),
                ),
                filled: true,
                fillColor: AppColors.secondaryBackgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
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
                padding: const EdgeInsets.all(12.0),
                child:
                    _isSendingMessage
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
