import 'dart:async';
import 'package:event_bus/event_bus.dart';
class ChatMessageEvent {
  final dynamic message;
  ChatMessageEvent(this.message);
}

class ChatRecallEvent {
  final int messageId;
  ChatRecallEvent(this.messageId);
}

class ChatReactionEvent {
  final int messageId;
  final String type;
  ChatReactionEvent(this.messageId, this.type);
}
class ProfileUpdateEvent {
  final int targetUserId;
  final bool isFollowing;

  ProfileUpdateEvent({
    required this.targetUserId,
    required this.isFollowing,
  });
}

class ModelProcessedEvent {
  final int modelId;
  final String status;

  ModelProcessedEvent({
    required this.modelId,
    required this.status,
  });
}

class GlobalEventBus {
  static final GlobalEventBus _instance = GlobalEventBus._internal();

  factory GlobalEventBus() {
    return _instance;
  }

  GlobalEventBus._internal();

  final _profileUpdateController = StreamController<void>.broadcast();

  Stream<void> get onProfileUpdateNeeded => _profileUpdateController.stream;
  final EventBus eventBus = EventBus();
  void fireMessageReceived(dynamic msg) => eventBus.fire(ChatMessageEvent(msg));
  void fireMessageRecalled(int id) => eventBus.fire(ChatRecallEvent(id));
  void fireReactionAdded(int id, String type) => eventBus.fire(ChatReactionEvent(id, type));

  Stream<ChatMessageEvent> get onMessageReceived => eventBus.on<ChatMessageEvent>();
  Stream<ChatRecallEvent> get onMessageRecalled => eventBus.on<ChatRecallEvent>();
  Stream<ChatReactionEvent> get onMessageReaction => eventBus.on<ChatReactionEvent>();
  void fireProfileUpdate(int targetUserId, bool isFollowing) {
    eventBus.fire(ProfileUpdateEvent(
      targetUserId: targetUserId,
      isFollowing: isFollowing,
    ));
  }

  void fireModelProcessed(int modelId, String status) {
    eventBus.fire(ModelProcessedEvent(
      modelId: modelId,
      status: status,
    ));
  }

  void dispose() {
    _profileUpdateController.close();
  }
}