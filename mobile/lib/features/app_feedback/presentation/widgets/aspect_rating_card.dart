import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class AspectRatingCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const AspectRatingCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.rating,
    required this.onRatingChanged,
  });

  String _getRatingLabel(int value) {
    switch (value) {
      case 1:
        return 'Sangat Kurang';
      case 2:
        return 'Kurang';
      case 3:
        return 'Cukup';
      case 4:
        return 'Baik';
      case 5:
        return 'Sangat Baik';
      default:
        return 'Belum Dinilai';
    }
  }

  Color _getRatingColor(int value) {
    switch (value) {
      case 1:
      case 2:
        return AppColors.coral;
      case 3:
        return const Color(0xFFE67E22);
      case 4:
      case 5:
        return const Color(0xFF27AE60);
      default:
        return AppColors.espresso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.surface(context);
    final borderColor = AppColors.border(context);
    final textColor = AppColors.text(context);
    final subtextColor = AppColors.subtext(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rating > 0
              ? AppColors.forestGreen.withValues(alpha: isDark ? 0.4 : 0.25)
              : borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppColors.espresso.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.forestGreenLight : AppColors.forestGreen)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDark ? AppColors.coral : AppColors.forestGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtextColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Star Rating Row & Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Stars (1–5)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isSelected = starIndex <= rating;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onRatingChanged(starIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Icon(
                        isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 32,
                        color: isSelected
                            ? const Color(0xFFFFB300) // Rich Amber Gold
                            : subtextColor.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                }),
              ),

              // Rating Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRatingColor(rating).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getRatingLabel(rating),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _getRatingColor(rating),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

