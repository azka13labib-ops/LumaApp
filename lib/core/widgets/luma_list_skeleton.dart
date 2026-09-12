import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Shared skeleton for any list that shows [count] track/playlist tiles.
/// Shape: square leading thumbnail + two text placeholder lines + optional trailing.
class LumaListSkeleton extends StatelessWidget {
  const LumaListSkeleton({
    super.key,
    this.count = 7,
    this.showTrailing = false,
  });

  final int count;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final baseColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[300]!;
    final highlightColor = isDark ? const Color(0xFF2E2E2E) : Colors.grey[100]!;
    final placeholderColor = isDark ? Colors.white : Colors.black;

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: baseColor,
        highlightColor: highlightColor,
        duration: const Duration(milliseconds: 1200),
      ),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (_, __) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Container(height: 13, width: 180, color: placeholderColor),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(height: 11, width: 100, color: placeholderColor),
          ),
          trailing: showTrailing
              ? Container(width: 28, height: 28, color: placeholderColor)
              : null,
        ),
      ),
    );
  }
}
