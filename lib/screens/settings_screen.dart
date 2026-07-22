import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/constants/color_constants.dart';
import 'package:pda/providers/providers.dart';
import 'package:pda/services/authwrapper.dart';
import 'package:pda/utilities/gap_func.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final prefsAsync = ref.watch(sharedPrefsProvider);
    String? displayDb;

    if (prefsAsync.asData != null) {
      final prefs = prefsAsync.asData!.value;
      final odooDb = prefs.getString("db");
      final orgId = prefs.getString("organization_id");

      if (odooDb == null || odooDb.isEmpty) {
        displayDb = orgId ?? "N/A";
      } else {
        displayDb = odooDb;
      }
    } else {
      displayDb = "loading...";
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: onSecondaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ListView(
          children: [
            _buildSettingCard("User-Name", authState.userName, Icons.person),
            _buildSettingCard("ERP-URL", authState.erpUrl, Icons.mail),
            _buildSettingCard(
              "DATABASE / CLIENT CODE",
              displayDb,
              Symbols.database,
            ),
            // vertGap(0),
            logOut("Log-Out", Icons.logout),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(String label, String? value, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 30, color: primaryColor),
            horiGap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: onBackgroundColor,
                    ),
                  ),
                  Divider(),
                  Text(value ?? 'N/A', style: TextStyle(color: formfieldColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget logOut(String logOut, IconData icon) {
    return InkWell(
      onTap: () async {
        final navigator = Navigator.of(context);
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("Log-Out?"),
            content: const Text("Are you sure?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text("Log-Out"),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) =>
                Center(child: CircularProgressIndicator(color: primaryColor)),
          );

          await ref.read(authNotifierProvider.notifier).logout();

          if (context.mounted) {
            navigator.pop();
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const AuthWrapper(showLogOutSnackBar: true),
              ),
              (route) => false,
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(5),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 30, color: errorColor),
                horiGap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        logOut,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: errorColor,
                        ),
                      ),
                    ],
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
