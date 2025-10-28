import 'package:flutter/material.dart';

bool isWidthGreaterThan400(BuildContext context) {
  return MediaQuery.of(context).size.width > 500;
}
