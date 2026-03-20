class MessageResponse {
  final int messageId;
  final String senderName;
  final String content;
  final DateTime sentAt;
  final List<String> photos;
  final int? replyToMessageId;
  final List<MessageReactionResponse> reactions;

  MessageResponse({
    required this.messageId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    required this.photos,
    this.replyToMessageId,
    required this.reactions,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(
      messageId: json['messageId'],
      senderName: json['senderName'] ?? "Unknown",
      content: json['content'] ?? "",
      sentAt: DateTime.parse(json['sentAt']),
      photos: List<String>.from(json['photos'] ?? []),
      replyToMessageId: json['replyToMessageId'],
      reactions: (json['reactions'] as List?)
          ?.map((r) => MessageReactionResponse.fromJson(r))
          .toList() ?? [],
    );
  }
}

class MessageReactionResponse {
  final int accountId;
  final String reactionType;

  MessageReactionResponse({required this.accountId, required this.reactionType});

  factory MessageReactionResponse.fromJson(Map<String, dynamic> json) {
    return MessageReactionResponse(
      accountId: json['accountId'],
      reactionType: json['reactionType'],
    );
  }
}