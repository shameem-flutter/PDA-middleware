import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/constants/color_constants.dart';
import 'package:pda/providers/providers.dart';

class SearchField extends ConsumerStatefulWidget {
  const SearchField({
    super.key,
    this.hintText,
    this.icon,
    this.padding,
    this.onChanged,
    this.focusNode,
    this.controller,
  });
  final String? hintText;
  final Icon? icon;
  final EdgeInsets? padding;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextEditingController? controller;

  @override
  ConsumerState<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.text = ref.read(searchQueryProvider);
    _controller.addListener(() {
      final text = _controller.text;
      ref.read(searchQueryProvider.notifier).state = text;
      widget.onChanged?.call(text);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);

    return TextField(
      focusNode: widget.focusNode,
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.icon ?? const Icon(Icons.search, color: Colors.grey),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _controller.clear();
                  ref.read(searchQueryProvider.notifier).state = "";
                  widget.onChanged?.call("");
                },
              )
            : null,

        filled: true,
        fillColor: onPrimaryColor,

        contentPadding: widget.padding,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
