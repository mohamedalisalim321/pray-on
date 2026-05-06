import 'package:flutter/material.dart';

import 'package:adhan/adhan.dart';

class MyPrayer {
  final Prayer prayer;

  final String name;

  final IconData icon;

  final DateTime time;

  MyPrayer({
    required this.prayer,
    required this.name,
    required this.icon,
    required this.time,
  });
}
