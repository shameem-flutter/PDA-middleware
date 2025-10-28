// ignore_for_file: must_be_immutable
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/constants/color_constants.dart';
import 'package:pda/utilities/gap_func.dart';

class CustomFormField extends ConsumerStatefulWidget {
  CustomFormField({
    super.key,
    this.title,
    required this.controller,
    required this.validate,
    this.label,
    this.obscureText,
    this.keyboardType,
    this.onTap,
    this.readOnly,
    this.iconData,
    this.prefix,
    this.suffixIcon,
    this.validator,
    this.maxLength,
    this.minLines,
    this.maxLines,
    this.onChanged,
    this.iconColor,
    this.enableInteractiveSelection,
    this.inputFormatters,
    this.enabled = false,
    this.isInSideHome = true,
    this.needTitle = true,
    this.focusNode,
    this.hintText,
    this.fieldPadding,
  });

  final TextEditingController controller;
  final String? title;
  final IconData? iconData;
  final Color? iconColor;
  final String? label;
  final String? hintText;
  final bool validate;
  bool? obscureText;
  TextInputType? keyboardType;
  final Function? onTap;
  final Function(String)? onChanged;
  final bool? readOnly;
  final Widget? suffixIcon;
  final Widget? prefix;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final bool? enableInteractiveSelection;
  final bool? isInSideHome;
  final bool needTitle;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? fieldPadding;

  @override
  ConsumerState<CustomFormField> createState() => _CustomFormFieldState();
}

class _CustomFormFieldState extends ConsumerState<CustomFormField> {
  late FocusNode _focusNode;
  final GlobalKey<FormFieldState> _fieldKey = GlobalKey<FormFieldState>();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (widget.readOnly == true) {
        if (!_focusNode.hasFocus && widget.controller.text.isNotEmpty) {
          _fieldKey.currentState?.validate();
        }
      } else {
        if (!_focusNode.hasFocus) {
          _fieldKey.currentState?.validate();
        }
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.needTitle && widget.title != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Text(
              widget.validate ? "${widget.title} " : widget.title!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: formfieldColor,
              ),
            ),
          ),
        if (widget.needTitle && widget.title != null) vertGap(3),
        Padding(
          padding:
              widget.fieldPadding ?? const EdgeInsets.symmetric(horizontal: 20),
          child: TextFormField(
            //enabled: widget.enabled,
            key: _fieldKey,
            focusNode: widget.focusNode ?? _focusNode,
            inputFormatters: widget.inputFormatters,
            enableInteractiveSelection:
                widget.enableInteractiveSelection ?? true,
            autofocus: false,
            readOnly: widget.readOnly ?? false,
            onTap: widget.onTap != null
                ? () {
                    widget.onTap!();
                  }
                : null,
            controller: widget.controller,
            maxLength: widget.maxLength,
            minLines: widget.minLines,
            maxLines: widget.obscureText == true ? 1 : widget.maxLines,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: formfieldColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              filled: true,
              fillColor: onPrimaryColor,
              counterText: "",
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(12),
              ),

              //  labelText: widget.validate ? "${widget.title} *" : widget.title,
              //  labelStyle: TextStyle(
              //   color: greyColor.withValues(alpha: 0.8),
              //  fontSize: 16,
              // ),
              alignLabelWithHint: true,
              isDense: true,
              contentPadding: EdgeInsets.only(
                bottom: 14,
                top: 14,
                left: 16,
                right: 16,
              ),
              prefix: widget.prefix,
              prefixIcon: widget.iconData != null
                  ? Icon(
                      widget.iconData,
                      color:
                          widget.iconColor ??
                          secondaryColor.withValues(alpha: 0.1),
                      size: 20,
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
              suffixIconColor: primaryColor,
            ),
            onChanged: (value) {
              if (value.isNotEmpty && widget.onChanged != null) {
                widget.onChanged!(value);
              }
            },
            validator: (value) {
              if (widget.validate) {
                if (value == null || value.isEmpty) {
                  return "This field is required";
                }
                return widget.validator?.call(value);
              }

              if (widget.validator != null &&
                  value != null &&
                  value.isNotEmpty) {
                return widget.validator!.call(value);
              }

              return null;
            },

            style: TextStyle(color: Colors.black, fontSize: 16),
            obscureText: widget.obscureText ?? false,
            keyboardType: widget.keyboardType ?? TextInputType.text,
          ),
        ),
        vertGap(12),
      ],
    );
  }
}
