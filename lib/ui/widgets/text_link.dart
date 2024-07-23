import 'package:flutter/material.dart';

class TextLink extends StatelessWidget {
  final String text;
  final void Function() onPressed;
  const TextLink(this.text, {required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}