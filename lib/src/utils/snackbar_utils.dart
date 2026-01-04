import 'package:flutter/material.dart';

class SnackbarUtils {
  static void showUndoSnackBar(BuildContext context, String message, VoidCallback onUndo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: onUndo,
        ),
        duration: const Duration(milliseconds: 4000),
      ),
    );
  }
}
