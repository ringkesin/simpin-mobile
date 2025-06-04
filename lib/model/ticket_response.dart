// ticket_models.dart
import 'dart:convert';

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
  final dynamic createdBy; // Bisa jadi int atau objek dari API tiket list
  final int? updatedBy;
  final int? deletedBy;
  final int countNotif;
  final DateTime? createdAt;

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
      transactionId:
          json['transaction_id'].toString(), // Pastikan selalu string
      subject: json['subject'] as String,
      status: json['status'] as int,
      createdBy: json['created_by'], // Biarkan dynamic, bisa int atau objek
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
      success: json['success'] as bool? ?? false, // Handle null
      data: itemsList,
      message: json['message'] as String? ?? '', // Handle null
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

// --- MODEL UNTUK INFORMASI PENGIRIM PESAN CHAT (created_by object) ---
class ChatMessageSenderInfoModel {
  final int id;
  final String name;
  final String? username;
  final String? email;
  final String? mobile;
  final String? profilePhotoUrl;
  // Tambahkan field lain dari objek created_by jika diperlukan
  // final String? remarks;
  // final DateTime? validFrom;
  // final DateTime? validUntil;
  // final String? profilePhotoPath;

  ChatMessageSenderInfoModel({
    required this.id,
    required this.name,
    this.username,
    this.email,
    this.mobile,
    this.profilePhotoUrl,
    // this.remarks,
    // this.validFrom,
    // this.validUntil,
    // this.profilePhotoPath,
  });

  factory ChatMessageSenderInfoModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageSenderInfoModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown Sender',
      username: json['username'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      // remarks: json['remarks'] as String?,
      // validFrom: json['valid_from'] != null ? DateTime.tryParse(json['valid_from']) : null,
      // validUntil: json['valid_until'] != null ? DateTime.tryParse(json['valid_until']) : null,
      // profilePhotoPath: json['profile_photo_path'] as String?,
    );
  }
}

// --- MODEL PESAN CHAT (DIPERBARUI untuk created_by object) ---
class ChatMessageModel {
  final String tChatConversationsId;
  final String tChatId;
  final String messageText;
  final bool isReadUser;
  final bool isReadAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  // 'createdBy' sekarang adalah objek ChatMessageSenderInfoModel atau null
  final ChatMessageSenderInfoModel? createdByInfo;
  // 'createdById' untuk menyimpan ID pengirim, untuk kompatibilitas dan perbandingan mudah
  final int? createdById;
  final int? updatedBy; // Tetap integer karena API tidak menunjukkan perubahan
  final int? deletedBy; // Tetap integer

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
    this.createdByInfo,
    this.createdById,
    this.updatedBy,
    this.deletedBy,
    this.isCurrentUser = false,
  });

  factory ChatMessageModel.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
  }) {
    String cleanTChatId = (json['t_chat_id'] as String? ?? '').trim();
    dynamic createdByData =
        json['created_by']; // Bisa objek atau int (dari send message)

    ChatMessageSenderInfoModel? senderInfoModel;
    int? senderId;

    if (createdByData is Map<String, dynamic>) {
      senderInfoModel = ChatMessageSenderInfoModel.fromJson(createdByData);
      senderId = senderInfoModel.id;
    } else if (createdByData is int) {
      // Jika created_by adalah int (misalnya dari respons send message lama atau API lain)
      senderId = createdByData;
      // Anda bisa membuat senderInfoModel dummy jika perlu nama default
      // senderInfoModel = ChatMessageSenderInfoModel(id: senderId, name: "User $senderId");
    }

    bool currentUserFlag = false;
    if (currentUserId != null && senderId != null) {
      currentUserFlag = senderId == currentUserId;
    }

    bool parseReadStatus(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    return ChatMessageModel(
      tChatConversationsId: json['t_chat_conversations_id'] as String,
      tChatId: cleanTChatId,
      messageText: json['message_text'] as String,
      isReadUser: parseReadStatus(json['is_read_user']),
      isReadAdmin: parseReadStatus(json['is_read_admin']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt:
          json['deleted_at'] == null
              ? null
              : DateTime.parse(json['deleted_at'] as String),
      createdByInfo: senderInfoModel, // Simpan objek info pengirim
      createdById: senderId, // Simpan ID pengirim
      updatedBy: json['updated_by'] as int?,
      deletedBy: json['deleted_by'] as int?,
      isCurrentUser: currentUserFlag,
    );
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

    messagesList.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return ChatMessagesResponseModel(
      success: json['success'] as bool? ?? false, // Handle null
      data: messagesList,
      message: json['message'] as String? ?? '', // Handle null
    );
  }
}

// Model untuk respons POST /api/chat/message/add
class SendMessageResponseModel {
  final bool success;
  final ChatMessageModel? data;
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
    // Respons API send message mungkin masih mengirim 'created_by' sebagai integer.
    // ChatMessageModel.fromJson sudah diupdate untuk menangani ini.
    return SendMessageResponseModel(
      success: json['success'] as bool? ?? false, // Handle null
      data:
          json['success'] == true && json['data'] != null
              ? ChatMessageModel.fromJson(
                json['data'] as Map<String, dynamic>,
                currentUserId: currentUserId,
              )
              : null,
      message: json['message'] as String? ?? '', // Handle null
    );
  }
}
