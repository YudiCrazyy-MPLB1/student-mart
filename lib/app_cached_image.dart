import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'skeleton_widgets.dart';

/// Komponen universal pemuat gambar dari jaringan dengan dukungan caching disk
/// otomatis (via cached_network_image) dan placeholder shimmer yang terintegrasi.
class AppCachedNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Widget? fallbackIcon;
  final Color? backgroundColor;
  final Alignment alignment;

  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fallbackIcon,
    this.backgroundColor,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.zero;
    final resolvedUrl = ApiService.getImageUrl(imageUrl).trim();

    final defaultFallback = Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey.shade100,
      alignment: Alignment.center,
      child: fallbackIcon ??
          Icon(
            Icons.shopping_bag_outlined,
            size: (width != null && width! < 50) ? 22 : 36,
            color: Colors.grey.shade400,
          ),
    );

    if (resolvedUrl.isEmpty) {
      return ClipRRect(
        borderRadius: effectiveRadius,
        child: defaultFallback,
      );
    }

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: CachedNetworkImage(
        imageUrl: resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        placeholder: (context, url) =>
            placeholder ??
            SkeletonShimmer(
              child: Container(
                width: width,
                height: height ?? double.infinity,
                color: Colors.white,
              ),
            ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: backgroundColor ?? Colors.grey.shade100,
              alignment: Alignment.center,
              child: fallbackIcon ??
                  Icon(
                    Icons.broken_image_outlined,
                    size: (width != null && width! < 50) ? 22 : 36,
                    color: Colors.grey.shade400,
                  ),
            ),
      ),
    );
  }
}
