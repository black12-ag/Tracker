import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    required this.height,
    super.key,
    this.width,
    this.radius = 18,
    this.margin,
  });

  final double height;
  final double? width;
  final double radius;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.line.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class ReferenceListPageSkeleton extends StatelessWidget {
  const ReferenceListPageSkeleton({
    super.key,
    this.showTopCard = false,
    this.showSearch = true,
    this.itemCount = 5,
  });

  final bool showTopCard;
  final bool showSearch;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTopCard) ...[
          const SkeletonBox(height: 112, radius: 28),
          const SizedBox(height: 16),
        ],
        if (showSearch) ...[
          const SkeletonBox(height: 58, radius: 24),
          const SizedBox(height: 16),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.9)),
          ),
          child: Column(
            children: List.generate(itemCount, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 16),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(height: 16, width: 120, radius: 10),
                          SizedBox(height: 10),
                          SkeletonBox(height: 12, width: 180, radius: 10),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    SkeletonBox(height: 18, width: 64, radius: 10),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class ReferenceDashboardSkeleton extends StatelessWidget {
  const ReferenceDashboardSkeleton({super.key, this.showMoney = true});

  final bool showMoney;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(height: 22, width: 120, radius: 10),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(showMoney ? 5 : 3, (index) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 44) / 2,
              child: const SkeletonBox(height: 122, radius: 28),
            );
          }),
        ),
        const SizedBox(height: 18),
        const SkeletonBox(height: 20, width: 150, radius: 10),
        const SizedBox(height: 12),
        const ReferenceListPageSkeleton(showSearch: false, itemCount: 4),
      ],
    );
  }
}

class ReferenceReportsSkeleton extends StatelessWidget {
  const ReferenceReportsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SkeletonBox(height: 44, radius: 22),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(8, (index) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 56) / 2,
              child: const SkeletonBox(height: 110, radius: 28),
            );
          }),
        ),
      ],
    );
  }
}

class ReferenceOrderPageSkeleton extends StatelessWidget {
  const ReferenceOrderPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SkeletonBox(height: 24, width: 140, radius: 10),
        const SizedBox(height: 18),
        const SkeletonBox(height: 58, radius: 22),
        const SizedBox(height: 14),
        const SkeletonBox(height: 160, radius: 26),
        const SizedBox(height: 18),
        const SkeletonBox(height: 24, width: 120, radius: 10),
        const SizedBox(height: 14),
        const SkeletonBox(height: 58, radius: 22),
        const SizedBox(height: 14),
        const SkeletonBox(height: 58, radius: 22),
        const SizedBox(height: 18),
        const SkeletonBox(height: 76, radius: 26),
        const SizedBox(height: 18),
        Row(
          children: const [
            Expanded(child: SkeletonBox(height: 52, radius: 22)),
            SizedBox(width: 14),
            Expanded(child: SkeletonBox(height: 52, radius: 22)),
          ],
        ),
      ],
    );
  }
}
