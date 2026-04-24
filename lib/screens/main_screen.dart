import 'package:fashion_mobile/screens/events_screen/event_list_screen.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../utils/global_event_bus.dart';
import 'home_screen.dart';
import './navbar_screens/search_screen.dart';
import './navbar_screens/profile_screen.dart';
import './navbar_screens/wardrobe_screen.dart';


import '../widgets/main_bottom_nav.dart';
final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    _startServices();

  }
  Future<void> _startServices() async {
    NotificationService.globalContext = context;
    await NotificationService().initNotificationService();
    await ChatService().initSignalR(
      onMessageReceived: (msg) {
        GlobalEventBus().fireMessageReceived(msg);
      },
      onMessageRecalled: (id) => GlobalEventBus().fireMessageRecalled(id),
      onReactionAdded: (id, type) => GlobalEventBus().fireReactionAdded(id, type),
    );
  }
  final List<Widget> _pages = [
    const HomeScreen(),
    const SearchScreen(),
    const EventListScreen(),
    const WardrobeScreen(),
    const ProfileScreen(),
  ];

  void switchTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: mainScreenKey,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: MainBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}