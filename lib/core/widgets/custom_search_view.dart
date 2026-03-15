import 'package:qwok/core/config/app_export.dart';

class CustomSearchView extends StatelessWidget {
  const CustomSearchView({
    super.key,
    this.alignment,
    this.width,
    this.scrollPadding,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.textStyle,
    this.hintText,
    this.hintStyle,
    this.prefix,
    this.prefixConstraints,
    this.suffix,
    this.suffixConstraints,
    this.contentPadding,
    this.borderDecoration,
    this.fillColor,
    this.filled = true,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.borderColor,
    this.backgroundColor,
  });

  final Alignment? alignment;
  final double? width;
  final EdgeInsets? scrollPadding;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool? autofocus;
  final TextStyle? textStyle;
  final String? hintText;
  final TextStyle? hintStyle;
  final Widget? prefix;
  final BoxConstraints? prefixConstraints;
  final Widget? suffix;
  final BoxConstraints? suffixConstraints;
  final EdgeInsets? contentPadding;
  final InputBorder? borderDecoration;
  final Color? fillColor;
  final bool? filled;
  final FormFieldValidator<String>? validator;
  final Function(String)? onChanged;
  final String? prefixIcon;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(
            alignment: alignment ?? Alignment.center,
            child: searchViewWidget(context),
          )
        : searchViewWidget(context);
  }

  Widget searchViewWidget(BuildContext context) => Container(
        width: width ?? double.infinity,
        height: 54.h,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(
            color: borderColor ?? appTheme.gray100.withValues(alpha: 0.5),
            width: 1.2.h,
          ),
          boxShadow: [
            BoxShadow(
              color: appTheme.black900.withValues(alpha: 0.03),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: TextFormField(
          scrollPadding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          controller: controller,
          focusNode: focusNode,
          onTapOutside: (event) {
            if (focusNode != null) {
              focusNode?.unfocus();
            } else {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          autofocus: autofocus!,
          style: textStyle ?? TextStyleHelper.instance.body14MediumPoppins,
          decoration: decoration,
          validator: validator,
          onChanged: (value) {
            onChanged?.call(value);
          },
        ),
      );

  InputDecoration get decoration => InputDecoration(
        hintText: hintText ?? "Search jobs, titles",
        hintStyle: hintStyle ??
            TextStyleHelper.instance.body14RegularPoppins.copyWith(
              color: appTheme.gray400.withValues(alpha: 0.8),
            ),
        prefixIcon: prefix ??
            (prefixIcon != null
                ? Padding(
                    padding: EdgeInsets.only(left: 14.w, right: 10.w),
                    child: CustomImageView(
                      imagePath: prefixIcon!,
                      height: 20.h,
                      width: 20.h,
                      color: appTheme.gray400,
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.only(left: 16.w, right: 8.w),
                    child: Icon(Icons.search, color: Colors.white, size: 20.h),
                  )),
        prefixIconConstraints: prefixConstraints ??
            BoxConstraints(
              minWidth: 44.w,
              maxHeight: 54.h,
            ),
        suffixIcon: suffix,
        suffixIconConstraints: suffixConstraints,
        isDense: true,
        contentPadding: contentPadding ??
            EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
        fillColor: Colors.transparent,
        filled: false,
        border: borderDecoration ?? InputBorder.none,
        enabledBorder: borderDecoration ?? InputBorder.none,
        focusedBorder: borderDecoration ?? InputBorder.none,
      );
}
