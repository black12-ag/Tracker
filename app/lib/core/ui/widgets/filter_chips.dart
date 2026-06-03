import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';

/// A single horizontally-scrolling row of mutually-exclusive filter chips,
/// styled to the app brand (navy selected, line border unselected). Used above
/// list screens to filter by status / stock level / partner type. Keep the
/// option set small (<= 6) so it reads at a glance.
class FilterChips extends StatelessWidget {
  const FilterChips({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// Ordered option keys. The first is treated as the "all" reset by callers.
  final List<FilterChipOption> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.value == selected;
          return _Chip(
            label: option.label,
            count: option.count,
            isSelected: isSelected,
            onTap: () => onSelected(option.value),
          );
        },
      ),
    );
  }
}

class FilterChipOption {
  const FilterChipOption(this.value, this.label, {this.count});

  final String value;
  final String label;

  /// Optional badge count (e.g. how many rows match this filter).
  final int? count;
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final fg = isSelected ? Colors.white : AppColors.warmGray;
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? AppColors.navy : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.navy : AppColors.line,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.warmGray,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
