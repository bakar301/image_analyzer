import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileSection(),
          const Divider(),
          _buildThemeSwitch(context),
          const Divider(),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: const Text('abubakar'),
      subtitle: const Text('@gmail.com'),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {/* Edit profile */},
      ),
    );
  }

  Widget _buildThemeSwitch(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return SwitchListTile(
          title: const Text('Dark Mode'),
          value: themeProvider.themeMode == ThemeMode.dark,
          onChanged: (value) => themeProvider.toggleTheme(value),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('Logout', style: TextStyle(color: Colors.red)),
      onTap: () {
        Provider.of<AuthProvider>(context, listen: false).logout();
        Navigator.pushReplacementNamed(context, '/login');
      },
    );
  }
}