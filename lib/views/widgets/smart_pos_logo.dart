import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// TokaPOS Logo Icon Widget (Tablet + TK + Struk Graphic)
class TokaPosLogoIcon extends StatelessWidget {
  final double size;
  final bool withBackground;
  final Color? backgroundColor;

  const TokaPosLogoIcon({
    super.key,
    this.size = 48,
    this.withBackground = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget icon = Image.asset(
      'assets/images/tokapos_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (ctx, err, stack) => Icon(
        Icons.point_of_sale_rounded,
        size: size,
        color: AppColors.accentOrange,
      ),
    );

    if (withBackground) {
      return Container(
        width: size * 1.25,
        height: size * 1.25,
        padding: EdgeInsets.all(size * 0.15),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: icon,
      );
    }

    return icon;
  }
}

/// Backward compatibility alias
typedef SmartPosLogoIcon = TokaPosLogoIcon;

/// Full TokaPOS Logo Widget (Icon + "TokaPOS" Wordmark)
class TokaPosLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool isDarkBackground;
  final bool showSubtitle;

  const TokaPosLogo({
    super.key,
    this.iconSize = 36,
    this.fontSize = 20,
    this.isDarkBackground = false,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokaColor = isDarkBackground ? Colors.white : const Color(0xFF0C2340);
    final posColor = AppColors.accentOrange;
    final subtitleColor = isDarkBackground ? Colors.white70 : AppColors.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (iconSize > 0) ...[
          TokaPosLogoIcon(
            size: iconSize,
            withBackground: isDarkBackground,
            backgroundColor: isDarkBackground ? Colors.white : null,
          ),
          SizedBox(width: iconSize * 0.28),
        ],
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
                children: [
                  TextSpan(
                    text: 'Toka',
                    style: TextStyle(
                      color: tokaColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: 'POS',
                    style: TextStyle(
                      color: posColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (showSubtitle)
              Text(
                'Point of Sale Modern',
                style: TextStyle(
                  fontSize: fontSize * 0.44,
                  color: subtitleColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Backward compatibility alias
typedef SmartPosLogo = TokaPosLogo;
