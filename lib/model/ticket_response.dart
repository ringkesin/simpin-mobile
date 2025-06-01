// ticket_models.dart

// Model untuk respons dari /api/master/chat-reference-table
class ChatReferenceTableResponse {
  final bool success;
  final List<ChatReferenceTableItem> data;
  final String message;

  ChatReferenceTableResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory ChatReferenceTableResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<ChatReferenceTableItem> itemsList =
        list.map((i) => ChatReferenceTableItem.fromJson(i)).toList();
    return ChatReferenceTableResponse(
      success: json['success'],
      data: itemsList,
      message: json['message'],
    );
  }
}

class ChatReferenceTableItem {
  final int pChatReferenceTableId;
  final String referenceTableName;
  final String customName;
  final String referenceTableKeyName;

  ChatReferenceTableItem({
    required this.pChatReferenceTableId,
    required this.referenceTableName,
    required this.customName,
    required this.referenceTableKeyName,
  });

  factory ChatReferenceTableItem.fromJson(Map<String, dynamic> json) {
    return ChatReferenceTableItem(
      pChatReferenceTableId: json['p_chat_reference_table_id'],
      referenceTableName: json['reference_table_name'] ?? '',
      customName: json['custom_name'] ?? 'Unknown Reference',
      referenceTableKeyName: json['reference_table_key_name'] ?? '',
    );
  }

  @override
  String toString() {
    return customName;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatReferenceTableItem &&
          runtimeType == other.runtimeType &&
          pChatReferenceTableId == other.pChatReferenceTableId;

  @override
  int get hashCode => pChatReferenceTableId.hashCode;
}

// Model untuk respons dari /api/chat/ticket/add
class CreateTicketResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  CreateTicketResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CreateTicketResponse.fromJson(Map<String, dynamic> json) {
    return CreateTicketResponse(
      success: json['success'],
      message: json['message'],
      data:
          json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    );
  }
}

// Model untuk setiap item tiket dalam daftar
class TicketListItemModel {
  final String tChatId;
  final String ticketCode;
  final int pChatReferenceTableId;
  final String transactionId;
  final String subject;
  final int status;
  final int createdBy;
  final int? updatedBy;
  final int? deletedBy;
  final int countNotif;
  final DateTime?
  createdAt; // Tambahkan createdAt jika ada di API dan dibutuhkan

  TicketListItemModel({
    required this.tChatId,
    required this.ticketCode,
    required this.pChatReferenceTableId,
    required this.transactionId,
    required this.subject,
    required this.status,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
    required this.countNotif,
    this.createdAt,
  });

  factory TicketListItemModel.fromJson(Map<String, dynamic> json) {
    return TicketListItemModel(
      tChatId: json['t_chat_id'] as String,
      ticketCode: json['ticket_code'] as String,
      pChatReferenceTableId: json['p_chat_reference_table_id'] as int,
      transactionId: json['transaction_id'] as String,
      subject: json['subject'] as String,
      status: json['status'] as int,
      createdBy: json['created_by'] as int,
      updatedBy: json['updated_by'] as int?,
      deletedBy: json['deleted_by'] as int?,
      countNotif: json['count_notif'] as int,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'])
              : null,
    );
  }

  String get statusDisplay {
    switch (status) {
      case 0:
        return 'Baru';
      case 1:
        return 'Diproses';
      case 2:
        return 'Selesai';
      case 3:
        return 'Dibatalkan';
      default:
        return 'Tidak Diketahui ($status)';
    }
  }
}

class TicketListResponseModel {
  final bool success;
  final List<TicketListItemModel> data;
  final String message;

  TicketListResponseModel({
    required this.success,
    required this.data,
    required this.message,
  });

  factory TicketListResponseModel.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List?;
    List<TicketListItemModel> itemsList =
        list != null
            ? list
                .map(
                  (i) =>
                      TicketListItemModel.fromJson(i as Map<String, dynamic>),
                )
                .toList()
            : [];

    return TicketListResponseModel(
      success: json['success'] as bool,
      data: itemsList,
      message: json['message'] as String,
    );
  }
}

class TicketListFilterPayload {
  final int? pChatReferenceTableId;
  final int? transactionId;
  final String? subject;

  TicketListFilterPayload({
    this.pChatReferenceTableId,
    this.transactionId,
    this.subject,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (pChatReferenceTableId != null) {
      data['p_chat_reference_table_id'] = pChatReferenceTableId;
    }
    if (transactionId != null) {
      data['transaction_id'] = transactionId;
    }
    if (subject != null && subject!.isNotEmpty) {
      data['subject'] = subject;
    }
    return data;
  }
}

// --- MODEL BARU UNTUK PESAN CHAT ---

class ChatMessageModel {
  final String tChatConversationsId;
  final String tChatId;
  final String messageText;
  final bool isReadUser;
  final bool isReadAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int createdBy; // Untuk menentukan apakah pesan dari user atau admin
  final int? updatedBy;
  final int? deletedBy;

  // Tambahan untuk UI: penanda apakah pesan ini dari pengguna saat ini
  bool isCurrentUser;

  ChatMessageModel({
    required this.tChatConversationsId,
    required this.tChatId,
    required this.messageText,
    required this.isReadUser,
    required this.isReadAdmin,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.isCurrentUser = false, // Default false, akan di-set kemudian
  });

  factory ChatMessageModel.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
  }) {
    // Membersihkan tChatId dari spasi berlebih
    String cleanTChatId = (json['t_chat_id'] as String? ?? '').trim();

    ChatMessageModel message = ChatMessageModel(
      tChatConversationsId: json['t_chat_conversations_id'] as String,
      tChatId: cleanTChatId,
      messageText: json['message_text'] as String,
      // API mengirim boolean untuk is_read_user, tapi di respons POST mengirim 0/1
      // Kita akan handle keduanya
      isReadUser:
          json['is_read_user'] is bool
              ? json['is_read_user']
              : (json['is_read_user'] == 1),
      isReadAdmin:
          json['is_read_admin'] is bool
              ? json['is_read_admin']
              : (json['is_read_admin'] == 1),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt:
          json['deleted_at'] == null
              ? null
              : DateTime.parse(json['deleted_at'] as String),
      createdBy: json['created_by'] as int,
      updatedBy: json['updated_by'] as int?,
      deletedBy: json['deleted_by'] as int?,
    );
    if (currentUserId != null) {
      message.isCurrentUser = message.createdBy == currentUserId;
    }
    return message;
  }
}

// Model untuk respons GET /api/chat/message/open/{t_chat_id}
class ChatMessagesResponseModel {
  final bool success;
  final List<ChatMessageModel> data;
  final String message;

  ChatMessagesResponseModel({
    required this.success,
    required this.data,
    required this.message,
  });

  factory ChatMessagesResponseModel.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
  }) {
    var list = json['data'] as List?;
    List<ChatMessageModel> messagesList =
        list != null
            ? list
                .map(
                  (i) => ChatMessageModel.fromJson(
                    i as Map<String, dynamic>,
                    currentUserId: currentUserId,
                  ),
                )
                .toList()
            : [];

    // Urutkan pesan berdasarkan createdAt (dari yang paling lama ke terbaru)
    messagesList.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return ChatMessagesResponseModel(
      success: json['success'] as bool,
      data: messagesList,
      message: json['message'] as String,
    );
  }
}

// Model untuk respons POST /api/chat/message/add
class SendMessageResponseModel {
  final bool success;
  final ChatMessageModel? data; // Data berisi pesan yang baru dikirim
  final String message;

  SendMessageResponseModel({
    required this.success,
    this.data,
    required this.message,
  });

  factory SendMessageResponseModel.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
  }) {
    return SendMessageResponseModel(
      success: json['success'] as bool,
      data:
          json['success'] == true && json['data'] != null
              ? ChatMessageModel.fromJson(
                json['data'] as Map<String, dynamic>,
                currentUserId: currentUserId,
              )
              : null,
      message: json['message'] as String,
    );
  }
}
