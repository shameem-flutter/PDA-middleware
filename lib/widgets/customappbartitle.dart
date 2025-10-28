import 'package:flutter/material.dart';
import 'package:pda/constants/color_constants.dart';

class CustomAppBarTitle extends StatelessWidget {
  final String title;
  const CustomAppBarTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: onSecondaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}
