import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:work_hub/core/config/app_export.dart';

class CustomImageView extends StatelessWidget {
  final String? imagePath;
  final double? height;
  final double? width;
  final Color? color;
  final BoxFit? fit;
  final String placeHolder;
  final Alignment? alignment;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? radius;
  final BoxBorder? border;
  final bool showLoadingIndicator;

  const CustomImageView({super.key, 
    this.imagePath,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.placeHolder = 'assets/images/placeholder_user.png',
    this.alignment,
    this.onTap,
    this.margin,
    this.radius,
    this.border,
    this.showLoadingIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(alignment: alignment!, child: _buildWidget())
        : _buildWidget();
  }

  Widget _buildWidget() {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: _buildCircleImage(),
      ),
    );
  }

  Widget _buildCircleImage() {
    if (radius != null) {
      return ClipRRect(
        borderRadius: radius!,
        child: _buildImageWithBorder(),
      );
    } else {
      return _buildImageWithBorder();
    }
  }

  Widget _buildImageWithBorder() {
    if (border != null) {
      return Container(
        decoration: BoxDecoration(
          border: border,
          borderRadius: radius,
        ),
        child: _buildImageView(),
      );
    } else {
      return _buildImageView();
    }
  }

  Widget _buildImageView() {
    if (imagePath == null || imagePath!.isEmpty) {
      return Image.asset(
        placeHolder,
        height: height,
        width: width,
        fit: fit,
      );
    }
    if (imagePath!.startsWith('http') || imagePath!.startsWith('https')) {
      return CachedNetworkImage(
        height: height,
        width: width,
        fit: fit,
        imageUrl: imagePath!,
        color: color,
        memCacheHeight: height != null && height!.isFinite && height! > 0
            ? (height! * 2).toInt()
            : 400,
        memCacheWidth: width != null && width!.isFinite && width! > 0
            ? (width! * 2).toInt()
            : 400,
        placeholder: (context, url) => showLoadingIndicator
            ? SizedBox(
                height: 30,
                width: 30,
                child: LinearProgressIndicator(
                  color: Colors.grey.shade200,
                  backgroundColor: Colors.grey.shade100,
                ),
              )
            : const SizedBox.shrink(),
        errorWidget: (context, url, error) => Image.asset(
          placeHolder,
          height: height,
          width: width,
          fit: fit,
        ),
      );
    } else if (imagePath!.startsWith('/') || imagePath!.contains(':\\')) {
      return Image.file(
        File(imagePath!),
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            placeHolder,
            height: height,
            width: width,
            fit: fit,
          );
        },
      );
    } else if (imagePath!.endsWith('.svg')) {
      return SvgPicture.asset(
        imagePath!,
        height: height,
        width: width,
        fit: fit ?? BoxFit.contain,
        colorFilter:
            color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      );
    } else if (imagePath!.startsWith('assets/')) {
      return Image.asset(
        imagePath!,
        height: height,
        width: width,
        fit: fit,
        color: color,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          placeHolder,
          height: height,
          width: width,
          fit: fit,
        ),
      );
    } else {
      // Fallback for unknown/garbage strings (e.g. "hush", "jsjs")
      // Do NOT try Image.file here as it might crash or be invalid.
      // Just show the placeholder.
      return Image.asset(
        placeHolder,
        height: height,
        width: width,
        fit: fit,
        color: color,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            height: height,
            width: width,
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
        },
      );
    }
  }
}



