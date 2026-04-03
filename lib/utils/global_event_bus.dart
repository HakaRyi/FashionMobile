import 'dart:async';
import 'package:event_bus/event_bus.dart';
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