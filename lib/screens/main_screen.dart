import 'package:fashion_mobile/screens/events_screen/event_list_screen.dart';
import 'package:flutter/material.dart';
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