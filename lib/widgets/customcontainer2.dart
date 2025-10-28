import 'package:flutter/material.dart';
import 'package:pda/constants/color_constants.dart';

class CustomContainer2 extends StatelessWidget {
  final String units;
  final String status;
  const CustomContainer2({
    super.key,
    required this.units,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: fadeColor,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Variance:",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(units, style: TextStyle(color: errorColor, fontSize: 17)),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text(status, style: TextStyle(fontSize: 17)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
