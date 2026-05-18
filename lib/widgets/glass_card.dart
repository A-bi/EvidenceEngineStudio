import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.card.withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}
