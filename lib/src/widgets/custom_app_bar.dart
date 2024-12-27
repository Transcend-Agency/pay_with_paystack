import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, this.onCloseTap});

  final VoidCallback? onCloseTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFD9D9D9),
            width: 1,
          ),
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          InkWell(
            onTap: onCloseTap,
            child: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.close, size: 26),
            ),
          ),
        ],
        title: const Column(
          children: [
            Text(
              'Payment',
              style: TextStyle(
                fontFamily: 'NeueMontreal',
                fontSize: 17,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
