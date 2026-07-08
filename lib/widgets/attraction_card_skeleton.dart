import 'package:flutter/material.dart';
import 'package:travel_memories/widgets/shimmer_box.dart';

class AttractionCardSkeleton extends StatelessWidget {
  const AttractionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ShimmerBox(
        width: 120,
        height: 200,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}