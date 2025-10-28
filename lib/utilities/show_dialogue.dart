import 'package:flutter/material.dart';

void showMessage(BuildContext context, String msg) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) =>
        FadeMessageWidget(message: msg, color: Colors.black, entry: entry),
  );

  overlay.insert(entry);
}

class FadeMessageWidget extends StatefulWidget {
  final String message;
  final Color color;
  final OverlayEntry entry;

  const FadeMessageWidget({
    super.key,
    required this.message,
    required this.color,
    required this.entry,
  });

  @override
  State<FadeMessageWidget> createState() => _FadeMessageWidgetState();
}

class _FadeMessageWidgetState extends State<FadeMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) _controller.reverse().then((_) => _removeOverlay());
    });
  }

  void _removeOverlay() {
    widget.entry.remove(); // use passed entry
  }

  void _closeManually() {
    _controller.reverse().then((_) => _removeOverlay());
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: widget.color,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                InkWell(
                  onTap: _closeManually,
                  child: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
