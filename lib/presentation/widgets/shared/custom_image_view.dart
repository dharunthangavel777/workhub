import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/app_export.dart';

class CustomImageView extends StatelessWidget {
  final String imagePath;
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

  CustomImageView({
    required this.imagePath,
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
    if (imagePath.isEmpty) {
      return Image.asset(
        placeHolder,
        height: height,
        width: width,
        fit: fit,
      );
    }
    if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
      return CachedNetworkImage(
        height: height,
        width: width,
        fit: fit,
        imageUrl: imagePath,
        color: color,
        placeholder: (context, url) => Container(
          height: 30,
          width: 30,
          child: LinearProgressIndicator(
            color: Colors.grey.shade200,
            backgroundColor: Colors.grey.shade100,
          ),
        ),
        errorWidget: (context, url, error) => Image.asset(
          placeHolder,
          height: height,
          width: width,
          fit: fit,
        ),
      );
    } else if (imagePath.endsWith('.svg')) {
      return SvgPicture.asset(
        imagePath,
        height: height,
        width: width,
        fit: fit ?? BoxFit.contain,
        colorFilter:
            color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      );
    } else {
      return Image.asset(
        imagePath,
        height: height,
        width: width,
        fit: fit,
        color: color,
      );
    }
  }
}
