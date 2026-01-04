import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'custom_colors.dart';

class TextStyleHelper {
  static final TextStyleHelper instance = TextStyleHelper._();
  TextStyleHelper._();

  // Poppins Styles
  TextStyle get title20SemiBoldPoppins => GoogleFonts.poppins(
        fontSize: 19.0,
        fontWeight: FontWeight.w600,
        color: CustomColors.darkText,
      );

  TextStyle get body14RegularPoppins => GoogleFonts.poppins(
        fontSize: 13.3,
        fontWeight: FontWeight.w400,
        color: CustomColors.textMuted,
      );

  TextStyle get body14MediumPoppins => GoogleFonts.poppins(
        fontSize: 13.3,
        fontWeight: FontWeight.w500,
        color: CustomColors.darkText,
      );

  TextStyle get body12SemiBoldPoppins => GoogleFonts.poppins(
        fontSize: 11.4,
        fontWeight: FontWeight.w600,
        color: CustomColors.darkText,
      );

  TextStyle get body12MediumPoppins => GoogleFonts.poppins(
        fontSize: 11.4,
        fontWeight: FontWeight.w500,
        color: CustomColors.darkText,
      );

  // DM Sans Styles
  TextStyle get title22BoldDMSans => GoogleFonts.dmSans(
        fontSize: 20.9,
        fontWeight: FontWeight.w700,
        color: CustomColors.darkText,
      );

  TextStyle get title20BlackDMSans => GoogleFonts.dmSans(
        fontSize: 19.0,
        fontWeight: FontWeight.w700,
        color: CustomColors.darkText,
      );

  TextStyle get body16RegularPoppins => GoogleFonts.poppins(
        fontSize: 15.2,
        fontWeight: FontWeight.w400,
        color: CustomColors.textMuted,
      );

  // Headline Styles
  TextStyle get headline24Bold => GoogleFonts.poppins(
        fontSize: 22.8,
        fontWeight: FontWeight.w700,
        color: CustomColors.darkText,
      );
}
