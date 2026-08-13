import 'package:flutter/material.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';
import 'package:zenfoo_partner/utils/app_fonts.dart';

class SlideActionButton extends StatefulWidget {
  final double height;
  final double width;
  final String text;
  final VoidCallback onComplete;

  const SlideActionButton({
    super.key,
    required this.onComplete,
    this.height = 60,
    this.width = 300,
    this.text = "Slide to Continue",
  });

  @override
  State<SlideActionButton> createState() => _SlideActionButtonState();
}

class _SlideActionButtonState extends State<SlideActionButton> {
  double position = 0.0;
  bool completed = false;

  @override
  Widget build(BuildContext context) {
    double maxPosition = widget.width - widget.height; // knob max slide

    return Container(
      height: widget.height,
      width: widget.width,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: position > 0
            ? AppColors.primaryColor.withOpacity(.4)
            : AppColors.primaryColor,
        borderRadius: BorderRadius.circular(widget.height / 2),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Slide Text
          Center(
            child: AnimatedOpacity(
              opacity: completed ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: Text(
                widget.text,
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontFamily: AppFonts.bold),
              ),
            ),
          ),

          // Knob (moving button)
          Positioned(
            left: position,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  position += details.delta.dx;
                  if (position < 0) position = 0;
                  if (position > maxPosition) position = maxPosition;
                });
              },
              onHorizontalDragEnd: (_) {
                if (position >= maxPosition - 10) {
                  // fully slided
                  setState(() {
                    completed = true;
                  });

                  widget.onComplete();

                  // Reset after completion
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) {
                      setState(() {
                        position = 0;
                        completed = false;
                      });
                    }
                  });
                } else {
                  // Not completed -> go back
                  setState(() {
                    position = 0;
                  });
                }
              },
              child: Container(
                height: widget.height - 10,
                width: widget.height - 10,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
