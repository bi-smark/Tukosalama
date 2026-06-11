import 'package:flutter/material.dart';

class SOSButton extends StatelessWidget {
  final VoidCallback onTap;

  const SOSButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        width: 150,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.4),
              spreadRadius: 10,
              blurRadius: 20,
            ),
          ],
          border: Border.all(color: Colors.white, width: 8),
        ),
        child: const Center(
          child: Text(
            "SOS",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
