import 'package:flutter/material.dart';

class OutlinedDropdown<T> extends StatelessWidget {
  const OutlinedDropdown({
    super.key,
    this.items,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.width,
    this.maxQnty,
    this.borderRadius = 12,
    this.isDense = true,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
    this.icon = const Icon(Icons.arrow_drop_down),
    this.validator,
    this.enabled = true,
  });

  final List<DropdownMenuItem<T>>? items;
  final int? maxQnty;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final double? width;
  final double borderRadius;
  final bool isDense;
  final EdgeInsetsGeometry contentPadding;
  final Widget icon;
  final String? Function(T?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final field = DropdownButtonHideUnderline(
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: enabled ? onChanged : null,
        icon: icon,
        isDense: isDense,
        isExpanded: false,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          isDense: isDense,
          contentPadding: contentPadding,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: Color(0xFFDFDFDF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: Color(0xFF9E9E9E), width: 1.2),
          ),
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }
}
