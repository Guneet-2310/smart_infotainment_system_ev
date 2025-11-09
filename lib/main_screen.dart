// lib/main_screen.dart
import 'package:ev_smart_screen/views/home_view.dart';
import 'package:ev_smart_screen/views/map_view.dart';
import 'package:ev_smart_screen/views/settings_view.dart';
import 'package:ev_smart_screen/views/stats_view.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Tracks which tab is currently selected

  // List of all the views
  static const List<Widget> _views = <Widget>[
    HomeView(),
    MapView(),
    StatsView(),
    SettingsView(),
  ];

  // Function to call when a tab is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body will be the currently selected view from our list
      body: Center(child: _views.elementAt(_selectedIndex)),

      // The 4-icon navigation bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent, // Color for selected icon
        unselectedItemColor: Colors.grey, // Color for unselected icons
        onTap: _onItemTapped,
        backgroundColor: Colors.black, // Navbar background color
        type: BottomNavigationBarType
            .fixed, // Ensures all 4 items are always visible
      ),
    );
  }
}
