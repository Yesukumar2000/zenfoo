import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomSearchDropdownField<T> extends StatefulWidget {
  final String title;
  final String hintText;
  final List<T> items;
  final String Function(T) itemTitle;
  final String Function(T)? itemSubtitle;
  final Widget Function(T)? itemTrailing;
  final void Function(T?)? onChanged;
  final T? selectedItem;
  final String? Function(T?)? validator;
  final bool enabled;
  final bool showClearButton;
  final bool readOnly;
  final TextEditingController? controller;

  const CustomSearchDropdownField({
    Key? key,
    required this.title,
    required this.hintText,
    required this.items,
    required this.itemTitle,
    this.itemSubtitle,
    this.itemTrailing,
    this.onChanged,
    this.selectedItem,
    this.validator,
    this.enabled = true,
    this.showClearButton = true,
    this.readOnly = false,
    this.controller,
  }) : super(key: key);

  @override
  State<CustomSearchDropdownField<T>> createState() => _CustomSearchDropdownFieldState<T>();
}

class _CustomSearchDropdownFieldState<T> extends State<CustomSearchDropdownField<T>> {
  String? _errorText;
  bool _hasFocus = false;
  late FocusNode _focusNode;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChanged);
    if (widget.selectedItem != null) {
      _controller.text = widget.itemTitle(widget.selectedItem!);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  void _selectItem(T? item) {
    setState(() {
      _errorText = null;
    });
    if (item != null) _controller.text = widget.itemTitle(item);
    widget.onChanged?.call(item);
  }

  void _clearSelection() {
    setState(() {
      _errorText = null;
    });
    _controller.clear();
    widget.onChanged?.call(null);
  }

  String? _validate(T? value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      setState(() {
        _errorText = error;
      });
      return error;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null && _errorText!.isNotEmpty;
    T? selected = widget.selectedItem;

    return GestureDetector(
      onTap: () async {
        if (!widget.enabled || widget.readOnly) return;
        FocusScope.of(context).unfocus();
        final chosen = await showDialog<T>(
          context: context,
          builder: (context) {
            return _CustomDropdownDialog<T>(
              items: widget.items,
              getTitle: widget.itemTitle,
              getSubtitle: widget.itemSubtitle,
              getTrailing: widget.itemTrailing,
              initialSelected: selected,
              searchHint: widget.hintText,
            );
          },
        );
        if (chosen != null) {
          _selectItem(chosen);
        }
      },
      child: AbsorbPointer(
        child: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  color: Color(0xFF1F1F1F),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                readOnly: true,
                onTap: widget.onChanged == null ? null : () {},
                style: GoogleFonts.inter(
                  color: Color(0xFF1F1F1F),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: GoogleFonts.inter(
                    color: Color(0xFF9E9E9E),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  filled: true,
                  fillColor: hasError
                      ? Color(0xFFFFF5F5)
                      : (_hasFocus ? Color(0xFFF8FBFF) : Color(0xFFF4F4F4)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showClearButton && _controller.text.isNotEmpty && !widget.readOnly)
                        GestureDetector(
                          onTap: _clearSelection,
                          child: Icon(Icons.cancel, size: 18, color: Color(0xFF9E9E9E)),
                        ),
                      Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF9E9E9E), size: 27),
                    ],
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: hasError ? Color(0xFFFF3B30) : Color(0xFFE5E5E5), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: hasError ? Color(0xFFFF3B30) : Color(0xFF1F5AF8), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFFF3B30), width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFFF3B30), width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                  ),
                  errorStyle: TextStyle(height: 0, fontSize: 0),
                  counterText: '',
                ),
                validator: (_) => _validate(selected),
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 14, color: Color(0xFFFF3B30)),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: GoogleFonts.inter(
                            color: Color(0xFFFF3B30),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomDropdownDialog<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) getTitle;
  final String Function(T)? getSubtitle;
  final Widget Function(T)? getTrailing;
  final T? initialSelected;
  final String searchHint;

  const _CustomDropdownDialog({
    Key? key,
    required this.items,
    required this.getTitle,
    this.getSubtitle,
    this.getTrailing,
    this.initialSelected,
    required this.searchHint,
  }) : super(key: key);

  @override
  State<_CustomDropdownDialog<T>> createState() => _CustomDropdownDialogState<T>();
}

class _CustomDropdownDialogState<T> extends State<_CustomDropdownDialog<T>> {
  late List<T> filteredItems;
  late TextEditingController searchController;
  T? selected;

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;
    searchController = TextEditingController();
    selected = widget.initialSelected;
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredItems = widget.items
          .where((item) => widget.getTitle(item).toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: TextFormField(
              controller: searchController,
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 15),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: GoogleFonts.inter(color: Color(0xFFA0A0A0), fontSize: 15),
                prefixIcon: Icon(Icons.search),
                fillColor: Color(0xFFF4F4F4),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 0),
              ),
            ),
          ),
          SizedBox(height: 7),
          Divider(),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 10),
              shrinkWrap: true,
              itemCount: filteredItems.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, idx) {
                final item = filteredItems[idx];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 6),
                  title: Text(widget.getTitle(item), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: widget.getSubtitle != null && widget.getSubtitle!(item).isNotEmpty
                      ? Text(widget.getSubtitle!(item), style: GoogleFonts.inter(fontSize: 12))
                      : null,
                  trailing: widget.getTrailing != null ? widget.getTrailing!(item) : null,
                  onTap: () => Navigator.of(context).pop(item),
                  selected: item == selected,
                  selectedTileColor: Color(0xFFF1FFF1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minLeadingWidth: 0,
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
