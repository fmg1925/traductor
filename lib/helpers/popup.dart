import 'package:flutter/material.dart';

class PopUp {
  static void showPopUp(BuildContext context, String title, String text) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(color: scheme.onPrimary)),
        content: Text(text, style: TextStyle(color: scheme.onPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: scheme.secondary)),
          ),
        ],
      ),
    );
  }
}
