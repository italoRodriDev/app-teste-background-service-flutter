import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Responsive and customizable animated buttons with an onPressed callback to have a natural feel.
class ToggleBubbleComponent extends StatefulWidget {
  const ToggleBubbleComponent(
      {required this.onPressed,
      this.shape = BoxShape.circle,
      this.buttonSize = 60,
      this.iconSize = 30,
      this.iconColor = Colors.pink,
      this.iconFlippedColor = Colors.white,
      this.icon = Icons.favorite_border,
      this.iconFlipped = Icons.favorite_border,
      this.duration = const Duration(milliseconds: 800),
      Key? key})
      : super(key: key);

  final double buttonSize;
  final double iconSize;
  final IconData icon;
  final IconData iconFlipped;
  final Color iconColor;
  final Color iconFlippedColor;
  final BoxShape shape;
  final Duration duration;
  final void Function() onPressed;

  @override
  _ToggleBubbleComponentState createState() => _ToggleBubbleComponentState();
}

class _ToggleBubbleComponentState extends State<ToggleBubbleComponent> {
  bool isPressed = false;
  bool isHighlighted = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.buttonSize,
      width: widget.buttonSize,
      child: InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onHighlightChanged: (value) {
          setState(() {
            isHighlighted = !isHighlighted;
          });
        },
        onTap: () {
          setState(() {
            isPressed = !isPressed;
            widget.onPressed();
          });
        },
        child: AnimatedContainer(
          margin: EdgeInsets.all(isHighlighted ? 1 : 2.5),
          height: isHighlighted ? widget.buttonSize : widget.buttonSize - 5,
          width: isHighlighted ? widget.buttonSize : widget.buttonSize - 5,
          curve: Curves.elasticOut,
          duration: widget.duration,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(5, 10),
              ),
            ],
            color: isPressed ? widget.iconColor : widget.iconFlippedColor,
            shape: widget.shape,
          ),
          child: isPressed
              ? Icon(
                  widget.iconFlipped,
                  size: widget.iconSize,
                  color: widget.iconFlippedColor,
                )
              : Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: widget.iconColor,
                ),
        ),
      ),
    );
  }
}
