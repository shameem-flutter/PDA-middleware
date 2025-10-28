import 'package:flutter/material.dart';
import 'package:pda/constants/color_constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final EdgeInsets? padding;
  final VoidCallback onPressed;
  final TextStyle? textStyle;
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.padding,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          foregroundColor: primaryColor,

          padding: padding,
        ),
        child: Text(text, style: textStyle),
      ),
    );
  }
}
