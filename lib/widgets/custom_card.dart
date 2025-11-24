import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const CustomCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1720), Color(0x0F0F1720)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30, offset: Offset(0,8))],
      ),
      child: child,
    );
  }
}
