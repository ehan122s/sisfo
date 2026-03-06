import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonWidget extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shape;

  const SkeletonWidget.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shape = const RoundedRectangleBorder();

  const SkeletonWidget.circular({
    super.key,
    required this.width,
    required this.height,
  }) : shape = const CircleBorder();

  const SkeletonWidget({
    super.key,
    required this.width,
    required this.height,
    this.shape = const RoundedRectangleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(color: Colors.grey[400]!, shape: shape),
      ),
    );
  }
}
