import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'custom_colors.dart';

class TextStyleHelper {
  static final TextStyleHelper instance = TextStyleHelper._();
  TextStyleHelper._();

  // Outfit Styles (Heading/Titles)
  TextStyle get headline22Bold => GoogleFonts.poppins(
        fontSize: 22.0,
        fontWeight: FontWeight.w700,
        color: CustomColors.darkText,
      );

  TextStyle get title20SemiBold => GoogleFonts.poppins(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: CustomColors.darkText,
      );

  TextStyle get title20Black => GoogleFonts.poppins(
        fontSize: 20.0,
        fontWeight: FontWeight.w900,
        color: CustomColors.darkText,
      );

  // Poppins Styles (Body/Labels)
  TextStyle get body16Regular => GoogleFonts.poppins(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        color: CustomColors.textMuted,
      );

  TextStyle get body16SemiBold => GoogleFonts.poppins(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        color: CustomColors.darkText,
      );

  TextStyle get body14Regular => GoogleFonts.poppins(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        color: CustomColors.textMuted,
      );

  TextStyle get body14Medium => GoogleFonts.poppins(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: CustomColors.darkText,
      );

  TextStyle get body12SemiBold => GoogleFonts.poppins(
        fontSize: 12.0,
        fontWeight: FontWeight.w600,
        color: CustomColors.darkText,
      );

  TextStyle get body12Medium => GoogleFonts.poppins(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        color: CustomColors.darkText,
      );

  TextStyle get body16Bold => GoogleFonts.poppins(
        fontSize: 16.0,
        fontWeight: FontWeight.w700,
        color: CustomColors.darkText,
      );

  TextStyle get body14Bold => GoogleFonts.poppins(
        fontSize: 14.0,
        fontWeight: FontWeight.w700,
        color: CustomColors.darkText,
      );

  TextStyle get body12Bold => GoogleFonts.poppins(
        fontSize: 12.0,
        fontWeight: FontWeight.w700,
        color: CustomColors.darkText,
      );

  TextStyle get body10Bold => GoogleFonts.poppins(
        fontSize: 10.0,
        fontWeight: FontWeight.w700,
        color: CustomColors.darkText,
      );

  TextStyle get body10Medium => GoogleFonts.poppins(
        fontSize: 10.0,
        fontWeight: FontWeight.w500,
        color: CustomColors.darkText,
      );

  TextStyle get body18Bold => GoogleFonts.poppins(
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
        color: CustomColors.darkText,
      );

  TextStyle get headline30Bold => GoogleFonts.poppins(
        fontSize: 30.0,
        fontWeight: FontWeight.w700,
        color: CustomColors.darkText,
      );

  // Backward compatibility aliases
  TextStyle get headline24Bold => headline22Bold;
  TextStyle get title20SemiBoldPoppins => title20SemiBold;
  TextStyle get title22BoldDMSans => headline22Bold;
  TextStyle get title20BlackDMSans => title20Black;
  TextStyle get body14RegularPoppins => body14Regular;
  TextStyle get body14MediumPoppins => body14Medium;
  TextStyle get body12SemiBoldPoppins => body12SemiBold;
  TextStyle get body12MediumPoppins => body12Medium;
  TextStyle get body16RegularPoppins => body16Regular;
}



