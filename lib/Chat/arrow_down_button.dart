import 'package:flutter/material.dart';

class ArrowDownButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ArrowDownButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: const Icon(Icons.arrow_downward),
    );
  }
}
