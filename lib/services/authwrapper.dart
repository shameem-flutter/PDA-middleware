import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/home.dart';
import 'package:pda/providers/providers.dart';
import 'package:pda/screens/loginscreen.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  final bool showLogOutSnackBar;
  const AuthWrapper({super.key, this.showLogOutSnackBar = false});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _snackBarShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.showLogOutSnackBar && !_snackBarShown) {
      _snackBarShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Logged out successfully"),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return authState.isLoggedIn
        ? const Home(initialIndex: 0)
        : LoginScreen(onLogin: () {});
  }
}
