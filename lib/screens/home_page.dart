// home_page.dart
import 'package:flutter/material.dart';
import 'package:image_analyzer/screens/analyze_page.dart';
import 'package:image_analyzer/screens/camera_page.dart';
import 'package:image_analyzer/screens/history_page.dart';
import 'package:image_analyzer/screens/settings_page.dart';
import '../globals.dart'; // Import the global cameras list

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const AnalyzePage(),
      // Pass the global cameras list to the CameraPage.
      CameraPage(cameras: cameras),
      const HistoryPage(),
      const SettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Analyze'),
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Camera'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
