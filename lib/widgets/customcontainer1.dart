import 'package:flutter/material.dart';
import 'package:pda/constants/color_constants.dart';

class ReviewCountContainer extends StatelessWidget {
  final String product;
  final String ucode;
  final String count;
  final String cerp;
  final Color color;

  const ReviewCountContainer({
    super.key,
    required this.color,
    required this.product,
    required this.ucode,
    required this.count,
    required this.cerp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        children: [
          Row(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ucode,
                      style: TextStyle(color: fadeColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(count, style: TextStyle(fontSize: 15, color: color)),
                  Text(cerp, style: TextStyle(color: fadeColor, fontSize: 12)),
                ],
              ),
            ],
          ),
          Divider(color: fadeColor, thickness: .5),
        ],
      ),
    );
  }
}
