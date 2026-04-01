import 'package:signalr_netcore/signalr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api_constants.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _hubConnection;
  Function(dynamic)? onNewOrderReceived;

  Future<void> initSignalR() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    if (userId == 0) return;

    _hubConnection = HubConnectionBuilder()
        .withUrl('${ApiConstants.baseUrl}/orderHub?userId=$userId')
        .withAutomaticReconnect()
        .build();

    _hubConnection!.on("ReceiveNewOrder", _handleNewOrder);

    try {
      await _hubConnection!.start();
    } catch (e) {
      throw Exception(e);
    }
  }

  void _handleNewOrder(List<dynamic>? parameters) {
    if (parameters != null && parameters.isNotEmpty) {
      if (onNewOrderReceived != null) {
        onNewOrderReceived!(parameters[0]);
      }
    }
  }

  void stopSignalR() {
    _hubConnection?.stop();
  }
}