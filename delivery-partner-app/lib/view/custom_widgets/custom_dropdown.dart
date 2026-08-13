import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDropdown<T> extends StatefulWidget {
  final T? selectedValue;
  final List<T> items;
  final String Function(T) itemLabel;
  final Function(T?) onChanged;
  final String hintText;

  final double height;
  final double borderRadius;
  final double? width;

  const CustomDropdown({
    super.key,
    required this.selectedValue,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.hintText,
    this.height = 46,
    this.borderRadius = 10,
    this.width,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _dropdownOverlay;
  bool isOpen = false;

  /// ---------------- CLOSE DROPDOWN ----------------
  void _closeDropdown() {
    if (!isOpen) return;
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
    setState(() => isOpen = false);
  }

  /// ---------------- TOGGLE ----------------
  void _toggleDropdown() {
    if (isOpen) {
      _closeDropdown();
    } else {
      _createDropdown();
    }
  }

  /// ---------------- CREATE CUSTOM OVERLAY ----------------
  void _createDropdown() {
    RenderBox box = context.findRenderObject() as RenderBox;
    Size widgetSize = box.size;
    Offset widgetPos = box.localToGlobal(Offset.zero);

    _dropdownOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Outside tap
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeDropdown,
            child: Container(color: Colors.transparent),
          ),

          // Dropdown
          Positioned(
            left: widgetPos.dx,
            top: widgetPos.dy + widgetSize.height + 4,
            width: widget.width ?? widgetSize.width,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: widget.items.map((item) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      onTap: () {
                        widget.onChanged(item);
                        _closeDropdown();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Text(
                          widget.itemLabel(item),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_dropdownOverlay!);
    setState(() => isOpen = true);
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String displayText = widget.selectedValue == null
        ? widget.hintText
        : widget.itemLabel(widget.selectedValue as T);

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          height: widget.height,
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: const Color(0xffD0D0D0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayText,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: widget.selectedValue == null
                        ? Colors.grey
                        : Colors.black,
                  ),
                ),
              ),
              Icon(
                isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
