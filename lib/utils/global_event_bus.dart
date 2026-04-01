import 'dart:async';

class GlobalEventBus {
  static final GlobalEventBus _instance = GlobalEventBus._internal();

  factory GlobalEventBus() {
    return _instance;
  }

  GlobalEventBus._internal();

  final _profileUpdateController = StreamController<void>.broadcast();

  Stream<void> get onProfileUpdateNeeded => _profileUpdateController.stream;

  void fireProfileUpdate() {
    _profileUpdateController.add(null);
  }

  void dispose() {
    _profileUpdateController.close();
  }
}