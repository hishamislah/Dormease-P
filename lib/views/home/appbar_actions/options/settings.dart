import 'package:dormease/translations/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:dormease/services/export_service.dart';
import 'reset_password_screen.dart';
import 'people_screen.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool autoBackupEnabled = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 245),
      appBar: AppBar(
        title: Text(LocaleKeys.settings.tr()),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSettingsSection(
                "Notifications",
                [
                  _buildSwitchTile(
                    "Push Notifications",
                    "Receive notifications for rent reminders and tickets",
                    notificationsEnabled,
                    Icons.notifications,
                    (value) {
                      setState(() {
                        notificationsEnabled = value;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              "Organization",
              [
                _buildActionTile(
                  "People",
                  "Manage team members and their roles",
                  Icons.people,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PeopleScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              "Appearance",
              [
                _buildSwitchTile(
                  "Dark Mode",
                  "Switch to dark theme",
                  darkModeEnabled,
                  Icons.dark_mode,
                  (value) {
                    setState(() {
                      darkModeEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              "Data & Storage",
              [
                _buildSwitchTile(
                  "Auto Backup",
                  "Automatically backup your data",
                  autoBackupEnabled,
                  Icons.backup,
                  (value) {
                    setState(() {
                      autoBackupEnabled = value;
                    });
                  },
                ),
                _buildActionTile(
                  "Export Data",
                  "Export your data as CSV",
                  Icons.download,
                  () async {
                    try {
                      final exportService = ExportService();
                      final filePath = await exportService.exportTenantData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Data exported successfully to \$filePath"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Failed to export data: \$e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              "Security",
              [
                _buildActionTile(
                  "Reset Password",
                  "Change your account password",
                  Icons.lock_reset,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ResetPasswordScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              "About",
              [
                _buildInfoTile("Version", "1.0.0", Icons.info),
                _buildActionTile(
                  "Privacy Policy",
                  "Read our privacy policy",
                  Icons.privacy_tip,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Privacy policy will open in browser"),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, IconData icon, Function(bool) onChanged) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.amber,
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber),
      title: Text(title),
      trailing: Text(value, style: const TextStyle(color: Colors.grey)),
    );
  }
}
