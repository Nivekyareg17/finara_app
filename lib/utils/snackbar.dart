import 'package:flutter/material.dart';

void showSnack(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  Color backgroundColor;
  IconData icon;

  if (isError) {
    backgroundColor = isDark ? Colors.red.shade400 : Colors.red;
    icon = Icons.error_outline;
  } else if (isSuccess) {
    backgroundColor = isDark ? Colors.green.shade400 : Colors.green;
    icon = Icons.check_circle_outline;
  } else {
    backgroundColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    icon = Icons.info_outline;
  }

  final textColor = isDark ? Colors.white : Colors.black87;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(12),
      content: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}