import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/constants/color_constants.dart';
import 'package:pda/providers/providers.dart';
import 'package:pda/services/authwrapper.dart';
import 'package:pda/utilities/gap_func.dart';
import 'package:pda/widgets/formfield.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _dbController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _dbController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if validation fails
    }

    log('Log in button pressed!');

    final success = await ref
        .read(authNotifierProvider.notifier)
        .login(
          baseUrl: _urlController.text.trim(),
          db: _dbController.text.trim(),
          username: usernameController.text.trim(),
          password: passwordController.text.trim(),
        );
    if (!mounted) return;

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logged-in successfuly"),
            duration: Duration(milliseconds: 500),
            backgroundColor: successColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        }
      });
    } else {
      log("Log in failed");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Log in failed. Please check credentials."),
          duration: Duration(milliseconds: 400),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "ERP Login",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: onSecondaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: AbsorbPointer(
        absorbing: authState.isLoading,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      vertGap(30),
                      Text(
                        "InventoryPro",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: primaryColor,
                        ),
                      ),
                      const Text("PDA Inventory Management"),
                      vertGap(40),

                      CustomFormField(
                        controller: _urlController,
                        validate: true,
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter ERP URL"
                            : null,
                        hintText: "https://your-erp.com",
                        title: "ERP URL",
                      ),
                      vertGap(10),

                      CustomFormField(
                        controller: _dbController,
                        validate: false,
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter database name"
                            : null,
                        hintText: "Company database",
                        title: "Database (odoo only)",
                      ),
                      vertGap(10),

                      CustomFormField(
                        controller: usernameController,
                        validate: true,
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter username"
                            : null,
                        hintText: "Your username",
                        title: "Username",
                      ),
                      vertGap(10),

                      CustomFormField(
                        controller: passwordController,
                        validate: true,
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter password"
                            : null,
                        hintText: "Your password",
                        title: "Password",
                        obscureText: true,
                      ),
                      vertGap(20),

                      SizedBox(
                        width: 333,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: authState.isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    horiGap(12),
                                    Text(
                                      "Logging in...",
                                      style: TextStyle(
                                        color: onSecondaryColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  "Login to ERP",
                                  style: TextStyle(
                                    color: onSecondaryColor,
                                    fontSize: 17,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
