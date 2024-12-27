import 'package:flutter/material.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    this.size = 25,
    this.icon,
    this.onTap,
    this.margin = 9,
  });

  final double size;
  final double margin;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(margin),
        child: Icon(icon, size: size, color: Colors.black),
      ),
    );
  }
}
