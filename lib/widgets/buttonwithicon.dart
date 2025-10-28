import 'package:flutter/material.dart';

class CustomButtonWithIcon extends StatelessWidget {
  final String text;
  final EdgeInsets? padding;
  final VoidCallback onPressed;
  final TextStyle? textStyle;
  final Icon? icon;
  const CustomButtonWithIcon({
    super.key,
    required this.text,
    required this.onPressed,
    this.padding,
    this.textStyle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        label: Text(text),
        icon: icon,
      ),
    );
  }
}
