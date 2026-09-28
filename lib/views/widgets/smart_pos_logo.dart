import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SmartPosLogoIcon extends StatelessWidget {
  final double size;
  final Color navyColor;
  final Color orangeColor;

  const SmartPosLogoIcon({
    super.key,
    this.size = 48,
    this.navyColor = AppColors.primaryNavy,
    this.orangeColor = AppColors.accentOrange,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SmartPosLogoPainter(
          navyColor: navyColor,
          orangeColor: orangeColor,
        ),
      ),
    );
  }
}

class _SmartPosLogoPainter extends CustomPainter {
  final Color navyColor;
  final Color orangeColor;

  _SmartPosLogoPainter({
    required this.navyColor,
    required this.orangeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final navyPaint = Paint()
      ..color = navyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final navyFill = Paint()
      ..color = navyColor
      ..style = PaintingStyle.fill;

    final orangePaint = Paint()
      ..color = orangeColor
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final orangeStroke = Paint()
      ..color = orangeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round;

    // --- 1. Terminal Body (Tilted Navy POS Device) ---
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.26, w * 0.44, h * 0.58),
      Radius.circular(w * 0.1),
    );

    canvas.save();
    canvas.translate(w * 0.4, h * 0.55);
    canvas.rotate(-0.20); // Slight tilt
    canvas.translate(-w * 0.4, -h * 0.55);

    // Terminal Outer Frame
    canvas.drawRRect(bodyRRect, navyPaint);

    // Terminal Display Screen (Top Half inside device)
    final screenRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.27, h * 0.31, w * 0.34, h * 0.24),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(screenRRect, navyPaint);

    // Checkmark inside screen
    final checkPath = Path()
      ..moveTo(w * 0.33, h * 0.42)
      ..lineTo(w * 0.40, h * 0.48)
      ..lineTo(w * 0.53, h * 0.35);
    canvas.drawPath(checkPath, navyPaint..strokeWidth = w * 0.065);

    // Keypad Grid (Bottom Half of terminal)
    final keyRadius = w * 0.025;
    canvas.drawCircle(Offset(w * 0.32, h * 0.62), keyRadius, navyFill);
    canvas.drawCircle(Offset(w * 0.44, h * 0.62), keyRadius, navyFill);
    canvas.drawCircle(Offset(w * 0.32, h * 0.70), keyRadius, navyFill);
    canvas.drawCircle(Offset(w * 0.44, h * 0.70), keyRadius, navyFill);

    // --- 2. Ascending Orange Arrow (Right side) ---
    final arrowPath = Path()
      ..moveTo(w * 0.52, h * 0.68)
      ..lineTo(w * 0.76, h * 0.28);
    canvas.drawPath(arrowPath, orangeStroke..strokeWidth = w * 0.11);

    // Fill arrow head tip cleanly
    final arrowHead = Path()
      ..moveTo(w * 0.76, h * 0.26)
      ..lineTo(w * 0.54, h * 0.28)
      ..lineTo(w * 0.76, h * 0.48)
      ..close();
    canvas.drawPath(arrowHead, orangePaint);

    // --- 3. Top Wi-Fi Signal Arcs with 'S' ---
    final wifiCenter = Offset(w * 0.44, h * 0.16);

    // Outer Arc
    canvas.drawArc(
      Rect.fromCircle(center: wifiCenter, radius: w * 0.18),
      -2.4, 1.7, false,
      orangeStroke..strokeWidth = w * 0.055,
    );
    // Inner Arc
    canvas.drawArc(
      Rect.fromCircle(center: wifiCenter, radius: w * 0.11),
      -2.4, 1.7, false,
      orangeStroke..strokeWidth = w * 0.05,
    );

    // Circle Badge with 'S' at center top
    final badgeCenter = Offset(w * 0.44, h * 0.18);
    canvas.drawCircle(badgeCenter, w * 0.065, orangePaint);

    // Draw letter 'S' inside circle
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'S',
        style: TextStyle(
          color: Colors.white,
          fontSize: w * 0.09,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(badgeCenter.dx - textPainter.width / 2, badgeCenter.dy - textPainter.height / 2),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SmartPosLogoPainter oldDelegate) {
    return oldDelegate.navyColor != navyColor || oldDelegate.orangeColor != orangeColor;
  }
}

/// Full Branding Logo Widget (Logo Graphic + "SMART POS" Text)
class SmartPosLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool isDarkBackground;
  final bool showSubtitle;

  const SmartPosLogo({
    super.key,
    this.iconSize = 40,
    this.fontSize = 20,
    this.isDarkBackground = false,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final navyText = isDarkBackground ? Colors.white : AppColors.primaryNavy;
    final mutedText = isDarkBackground ? Colors.white70 : AppColors.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SmartPosLogoIcon(
          size: iconSize,
          navyColor: isDarkBackground ? Colors.white : AppColors.primaryNavy,
          orangeColor: AppColors.accentOrange,
        ),
        SizedBox(width: iconSize * 0.25),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
                children: [
                  TextSpan(
                    text: 'SMART ',
                    style: TextStyle(color: navyText),
                  ),
                  TextSpan(
                    text: 'POS',
                    style: TextStyle(color: AppColors.accentOrange),
                  ),
                ],
              ),
            ),
            if (showSubtitle)
              Text(
                'Sistem Kasir Pintar',
                style: TextStyle(
                  fontSize: fontSize * 0.48,
                  color: mutedText,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
