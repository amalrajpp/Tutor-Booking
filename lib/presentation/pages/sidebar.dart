import 'package:flutter/material.dart';

// Define colors for easy reuse, matching the design
const Color _primaryColor = Color(0xFF3D82F8);
const Color _canvasColor = Color(0xFFFFFFFF);
const Color _textColor = Color(0xFF333333);
const Color _iconColor = Color(0xFF757575);
const Color _accountTextColor = Color(0xFFAAAAAA);
const Color _badgeGreenBg = Color(0xFFD4F8E5);
const Color _badgeGreenText = Color(0xFF3C855B);
const Color _badgeOrangeBg = Color(0xFFFDE8D4);
const Color _badgeOrangeText = Color(0xFFE58D35);
const Color _toggleBg = Color(0xFFF6F7F9);

class MarketerzSideMenu extends StatelessWidget {
  const MarketerzSideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Using Drawer for standard sidebar behavior
    return Drawer(
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.85, // Custom width
      child: Container(
        color: _canvasColor,
        child: Column(
          children: [
            Expanded(
              // Using ListView for the main scrollable content
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  // Top section with logo, name, and search
                  const SizedBox(height: 25),
                  _buildHeader(),

                  const SizedBox(height: 20),

                  // Main navigation items
                  _buildMenuItem(
                    icon: Icons.grid_view_rounded,
                    title: 'Dashboard',
                  ),
                  _buildMenuItem(
                    icon: Icons.widgets_outlined,
                    title: 'Products',
                  ),
                  _buildMenuItem(
                    icon: Icons.mail_outline_rounded,
                    title: 'Mail',
                  ),
                  _buildMenuItem(icon: Icons.flag_outlined, title: 'Campaigns'),
                  _buildMenuItem(
                    icon: Icons.calendar_today_outlined,
                    title: 'Calendar',
                  ),
                  _buildMenuItem(icon: Icons.person_outline, title: 'Contacts'),

                  // Divider
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Divider(height: 1, thickness: 1, color: _toggleBg),
                  ),

                  // Account section header
                  _buildAccountHeader(),
                  const SizedBox(height: 10),

                  // Account navigation items
                  _buildNotificationItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    count: '24',
                    badgeColor: _badgeGreenBg,
                    badgeTextColor: _badgeGreenText,
                  ),
                  _buildNotificationItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Chat',
                    count: '8',
                    badgeColor: _badgeOrangeBg,
                    badgeTextColor: _badgeOrangeText,
                  ),
                  _buildMenuItem(icon: Icons.tune_rounded, title: 'Settings'),
                ],
              ),
            ),
            // Pushes the user profile to the bottom
            _buildUserProfile(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper for the top header section
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.layers_rounded, color: _textColor, size: 28),
            SizedBox(width: 12),
            Text(
              'Karreo v1.0',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _textColor,
              ),
            ),
          ],
        ),
        const Icon(Icons.search, color: _textColor, size: 28),
      ],
    );
  }

  // Helper for the Personal/Business toggle
  Widget _buildToggleSwitch() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _toggleBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text(
                  'PERSONAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'BUSINESS',
                style: TextStyle(
                  color: _iconColor.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for standard menu items
  Widget _buildMenuItem({required IconData icon, required String title}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      leading: Icon(icon, color: _iconColor, size: 26),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: _textColor,
          fontSize: 16,
        ),
      ),
      onTap: () {
        // TODO: Add navigation logic
      },
    );
  }

  // Helper for the "ACCOUNT" text label
  Widget _buildAccountHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'ACCOUNT',
          style: TextStyle(
            color: _accountTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // Helper for menu items that include a notification badge
  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String count,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      leading: Icon(icon, color: _iconColor, size: 26),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: _textColor,
          fontSize: 16,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          count,
          style: TextStyle(
            color: badgeTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      onTap: () {
        // TODO: Add navigation logic
      },
    );
  }

  // Helper for the user profile section at the bottom
  Widget _buildUserProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage('assets/images/avatar.png'),
        ),
        title: const Text(
          'Nina Ergemla',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textColor,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'ninag@ergemia.com',
          style: TextStyle(color: _iconColor.withOpacity(0.8), fontSize: 13),
        ),
        trailing: const Icon(Icons.more_horiz, color: _iconColor),
        onTap: () {
          // TODO: Add logic for user profile actions
        },
      ),
    );
  }
}
