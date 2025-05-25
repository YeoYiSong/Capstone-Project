import 'package:flutter/material.dart';

class DoodleStroke {
  final List<Offset> points;
  final Color color;

  DoodleStroke({required this.points, required this.color});

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((offset) => [offset.dx, offset.dy]).toList(),
      'color': '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}',
    };
  }
}
