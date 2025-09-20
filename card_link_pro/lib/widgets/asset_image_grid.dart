import 'package:flutter/material.dart';

class AssetImageGrid extends StatelessWidget {
  const AssetImageGrid({
    super.key,
    required this.assets,
    required this.onPick,
    this.crossAxisCount = 3,
  });

  final List<String> assets;
  final ValueChanged<String> onPick;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: assets.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (_, i) {
        final a = assets[i];
        return InkWell(
          onTap: () => onPick(a),
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(a, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}
