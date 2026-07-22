import 'package:flutter/material.dart';
import 'package:pda/constants/color_constants.dart';

class CustomCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String info1;
  final String info2;
  final IconButton? iconButton2;
  final Color? cardColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final Widget? customWidget;

  const CustomCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.info1,
    required this.info2,
    this.cardColor,
    this.textColor,
    this.onTap,

    this.iconButton2,
    this.customWidget,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.image, size: 80),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.start,
                    ),

                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            widget.textColor?.withValues(alpha: 0.8) ??
                            Colors.grey[600],
                      ),
                    ),

                    Text(
                      widget.info1,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: onSurfaceColor,
                      ),
                    ),
                    Text(
                      widget.info2,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: fadeColor,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                children: [
                  if (widget.iconButton2 != null) widget.iconButton2!,
                  if (widget.customWidget != null) widget.customWidget!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
