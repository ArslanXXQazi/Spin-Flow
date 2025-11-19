

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Responsive {
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _baseFontSize;

  //===========>>> Initialize with BuildContext
  static void init(BuildContext context) {
    _screenWidth = MediaQuery.sizeOf(context).width;
    _screenHeight = MediaQuery.sizeOf(context).height;
    _baseFontSize = 16; // Base font size for scaling
  }

  //===========>>> Get responsive font size
  static double fontSize(double size) {
    return size * (_screenWidth / 375); // Scale based on 375px width (standard mobile)
  }

  //===========>>> Get responsive height
  static double height(double value) {
    return value * (_screenHeight / 750); // Scale based on 750px height
  }

  //===========>>> Get responsive width
  static double width(double value) {
    return value * (_screenWidth / 375); // Scale based on 375px width
  }
}

class BlackText extends StatelessWidget {
  final String? text;
  final VoidCallback? onTap;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? textColor;
  final TextAlign? textAlign;
  final String? fontFamily; // New parameter for font family
  final int? maxLines; // Added maxLines parameter
  final TextOverflow? overflow; // Added overflow parameter

  const BlackText({
    super.key,
    this.text,
    this.onTap,
    this.fontSize,
    this.fontWeight,
    this.textColor,
    this.textAlign,
    this.fontFamily,
    this.maxLines, // Added to control max lines
    this.overflow, // Added to control overflow behavior
  });

  @override
  Widget build(BuildContext context) {
    //===========>>> Initialize Responsive utility
    Responsive.init(context);

    final displayText = text?.replaceAll('"', '\\"') ?? "";

    // Determine which font to use
    TextStyle textStyle;
    if (fontFamily == 'a') {
      textStyle = GoogleFonts.bayon(
        fontSize: fontSize != null
            ? Responsive.fontSize(fontSize!)
            : Responsive.fontSize(16),
        fontWeight: fontWeight ?? FontWeight.w500,
        color: textColor ?? Colors.black,
      );
    } else {
      // Default to Poppins
      textStyle = GoogleFonts.geologica(
        fontSize: fontSize != null
            ? Responsive.fontSize(fontSize!)
            : Responsive.fontSize(16),
        fontWeight: fontWeight ?? FontWeight.w500,
        color: textColor ?? Colors.black,
      );
    }

    return InkWell(
      //===========>>> Tappable text container
      onTap: onTap ?? null,
      child: Text(
        //===========>>> Display text or empty string
        text ?? "",
        textAlign: textAlign ?? TextAlign.center,
        style: textStyle,
        maxLines: maxLines ?? 1000,
        overflow: overflow ?? TextOverflow.ellipsis, // Default to ellipsis for overflow
        softWrap: true, // Enable soft wrapping for natural line breaks
      ),
    );
  }
}