import 'package:flutter/material.dart';

class DemoProduct {
  const DemoProduct({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.category,
    required this.price,
    required this.color,
  });

  final String id;
  final String name;
  final String subtitle;
  final String category;
  final double price;
  final Color color;
}

const List<String> demoCategories = <String>['All', 'Focus', 'Audio', 'Desk'];

const List<DemoProduct> demoProducts = <DemoProduct>[
  DemoProduct(
    id: 'focus-lamp',
    name: 'Focus Lamp',
    subtitle: 'Warm desk light for late-night sprint sessions.',
    category: 'Desk',
    price: 89,
    color: Color(0xFFE2B66E),
  ),
  DemoProduct(
    id: 'wave-headset',
    name: 'Wave Headset',
    subtitle: 'Noise-softening headset tuned for mobile creators.',
    category: 'Audio',
    price: 149,
    color: Color(0xFF78A6A8),
  ),
  DemoProduct(
    id: 'daily-planner',
    name: 'Daily Planner',
    subtitle: 'A tactile sprint board for keeping tasks visible.',
    category: 'Focus',
    price: 28,
    color: Color(0xFFD87E62),
  ),
  DemoProduct(
    id: 'studio-timer',
    name: 'Studio Timer',
    subtitle: 'Pomodoro timer with ambient breathing light.',
    category: 'Focus',
    price: 64,
    color: Color(0xFF5A6FA8),
  ),
];
