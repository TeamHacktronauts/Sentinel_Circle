import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentinel_circle/core/theme_provider.dart';
import '../services/auth_service.dart';
import '../screens/trusted_parents_page.dart';
import '../screens/notifications_page.dart';
import '../screens/help_support_screen.dart';

class RightDrawer extends StatelessWidget {
  const RightDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Drawer Header
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_outline,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to home if needed
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.history,
                  title: 'Report History',
                  onTap: () {
                    // Handle report history
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_outline,
                  title: 'Trusted Parents',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrustedParentsPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    // Handle settings
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                // Theme Toggle
                ListTile(
                  leading: Icon(
                    Icons.brightness_6,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  title: const Text('Dark Mode'),
                  trailing: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) => Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme(value);
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onTap: () {
                    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                    themeProvider.toggleTheme(!themeProvider.isDarkMode);
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () async {
                    final authService = AuthService();
                    await authService.logout();
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/splash');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      onTap: onTap,
    );
  }
}
