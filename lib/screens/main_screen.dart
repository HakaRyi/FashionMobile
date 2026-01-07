import 'package:flutter/material.dart';
import 'home_screen.dart';
import './navbar_screens/search_screen.dart';

import '../widgets/main_bottom_nav.dart';

//File này chỉ dùng để load các màn hình trên bottom navigation bar nha
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  //Sau này có thêm trang nào trên Bottom Navigation Bar thì them vào mảng này
  final List<Widget> _pages = [
    const HomeScreen(),
    const SearchScreen(),
    const Center(child: Text("Post Page", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Activity Page", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Profile Page", style: TextStyle(color: Colors.white))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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