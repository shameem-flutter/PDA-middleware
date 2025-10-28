import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ErrorMessageText extends ConsumerWidget {
  final String message;
  final Color? color;
  const ErrorMessageText({super.key, required this.message, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
      message,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: color ?? Colors.black,
      ),
      textAlign: TextAlign.center,
    );
  }
}
