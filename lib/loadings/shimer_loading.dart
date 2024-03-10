import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget data;
  const ShimmerLoading({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Shimmer.fromColors(
        baseColor: const Color.fromARGB(255, 215, 226, 226),
        highlightColor: Colors.grey.shade100,
        enabled: true,
        child: data,
      ),
    ));
  }
}
