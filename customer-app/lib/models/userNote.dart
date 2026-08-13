class UserNoteResponse {
  String? status;
  String? message;
  String? total;
  List<UserNote>? data;

  UserNoteResponse({this.status, this.message, this.total, this.data});

  UserNoteResponse.fromJson(Map<String, dynamic> json) {
    status = json['status']?.toString();
    message = json['message']?.toString();
    total = json['total']?.toString();

    // Handle data as array directly
    if (json['data'] != null) {
      data = <UserNote>[];
      if (json['data'] is List) {
        json['data'].forEach((v) {
          data!.add(UserNote.fromJson(v));
        });
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonData = <String, dynamic>{};
    jsonData['status'] = status;
    jsonData['message'] = message;
    jsonData['total'] = total;
    if (data != null) {
      jsonData['data'] = data!.map((v) => v.toJson()).toList();
    }
    return jsonData;
  }
}

class UserNote {
  String? id;
  String? userId;
  String? noteText;
  bool isSelected;
  int orderIndex;
  String? createdAt;
  String? updatedAt;

  UserNote({
    this.id,
    this.userId,
    this.noteText,
    this.isSelected = true,
    this.orderIndex = 0,
    this.createdAt,
    this.updatedAt,
  });

  UserNote.fromJson(Map<String, dynamic> json)
      : id = json['id']?.toString(),
        userId = json['user_id']?.toString(),
        noteText = json['text']?.toString() ?? json['note_text']?.toString(),
        isSelected = json['is_selected'] == true ||
            json['is_selected'].toString() == '1' ||
            json['is_selected'].toString() == 'true',
        orderIndex = int.tryParse(json['order_index']?.toString() ?? '') ?? 0,
        createdAt = json['created_at']?.toString(),
        updatedAt = json['updated_at']?.toString();

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['note_text'] = noteText;
    data['is_selected'] = isSelected;
    data['order_index'] = orderIndex;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }

  // Copy with method for easy state updates
  UserNote copyWith({
    String? id,
    String? userId,
    String? noteText,
    bool? isSelected,
    int? orderIndex,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      noteText: noteText ?? this.noteText,
      isSelected: isSelected ?? this.isSelected,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Single note response (for add/update/delete operations)
class SingleUserNoteResponse {
  String? status;
  String? message;
  UserNote? note;
  String? deletedNoteId;

  SingleUserNoteResponse({
    this.status,
    this.message,
    this.note,
    this.deletedNoteId,
  });

  SingleUserNoteResponse.fromJson(Map<String, dynamic> json) {
    status = json['status']?.toString();
    message = json['message']?.toString();

    // Handle data as object with note property
    if (json['data'] != null) {
      if (json['data'] is Map<String, dynamic>) {
        Map<String, dynamic> data = json['data'];
        note = data['note'] != null ? UserNote.fromJson(data['note']) : null;
        deletedNoteId = data['deleted_note_id']?.toString();
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonData = <String, dynamic>{};
    jsonData['status'] = status;
    jsonData['message'] = message;

    Map<String, dynamic> data = {};
    if (note != null) {
      data['note'] = note!.toJson();
    }
    if (deletedNoteId != null) {
      data['deleted_note_id'] = deletedNoteId;
    }
    jsonData['data'] = data;

    return jsonData;
  }
}
