import 'package:flutter/material.dart';
import 'package:pda/constants/color_constants.dart';

class CustomButton2 extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final EdgeInsets? padding;
  final Size? size;
  const CustomButton2({
    super.key,
    required this.text,
    required this.onPressed,
    this.padding,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        fixedSize: size,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: padding,
      ),
      child: Text(text, style: TextStyle(fontSize: 17)),
    );
  }
}
