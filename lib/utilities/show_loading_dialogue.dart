// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pda/constants/color_constants.dart';

void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: const Color(0x00ffffff),
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Image.asset(
            //   "assets/images/wasla.png",
            //   height: 45,
            //   width: 45,
            //   color: primaryColor,
            // ),
            const SizedBox(
              height: 55,
              width: 55,
              child: CircularProgressIndicator(color: primaryColor),
            ),
          ],
        ),
      );
    },
  );
}

void closeLoadingDialog(BuildContext context) {
  Navigator.of(context).pop();
}
