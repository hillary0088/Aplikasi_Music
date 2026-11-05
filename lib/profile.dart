import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const ProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = isDarkMode
        ? const Color(0xFFFFD6E5)
        : const Color(0xFF9C2858);

    Color cardColor = isDarkMode
        ? const Color(0xFF493044)
        : const Color(0xFFFFD6E5);

    Color secondaryTextColor = isDarkMode
        ? const Color(0xFFE5AFC9)
        : const Color(0xFFB34D79);

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 65,
                  backgroundColor: Color(0xFFFF8FBA),
                  child: Icon(
                    Icons.person,
                    size: 75,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Hillary Natalia',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '825240086',
                  style: TextStyle(
                    fontSize: 15,
                    color: secondaryTextColor,
                  ),
                ),

                const SizedBox(height: 30),

                Card(
                  color: cardColor,
                  child: ListTile(
                    leading: const Icon(
                      Icons.music_note,
                      color: Color(0xFFE84393),
                    ),
                    title: Text(
                      'Hillary Natalia',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '825240086',
                      style: TextStyle(
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Card(
                  color: cardColor,
                  child: SwitchListTile(
                    secondary: const Icon(
                      Icons.dark_mode,
                      color: Color(0xFFE84393),
                    ),
                    title: Text(
                      'Dark Mode',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Aktifkan tampilan gelap',
                      style: TextStyle(
                        color: secondaryTextColor,
                      ),
                    ),
                    activeThumbColor: const Color(0xFFE84393),
                    value: isDarkMode,
                    onChanged: onThemeChanged,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}