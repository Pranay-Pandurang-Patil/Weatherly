import 'package:flutter/material.dart';

class Addinfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const Addinfo({super.key, required this.icon,required this.label,required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32),
        const SizedBox(width: 16),
        Text(label),
        const SizedBox(width: 16),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
