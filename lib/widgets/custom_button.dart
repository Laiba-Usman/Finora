import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: backgroundColor != null
          ? theme.elevatedButtonTheme.style?.copyWith(
              backgroundColor: WidgetStateProperty.all(backgroundColor),
            )
          : null,
      child: isLoading
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? (isDark ? Colors.black : Colors.white),
                ),
              ),
            )
          : Text(
              text,
              style: TextStyle(
                color: textColor, // Null allows button foregroundColor to propagate naturally
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
