import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:pda/constants/messages.dart';
import 'package:pda/widgets/error_text_message.dart';

class CheckConnectionWidget extends ConsumerStatefulWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? noConnectionWidget;
  final Color? textColor;
  final Function? function;
  final String offlineMessage;

  const CheckConnectionWidget({
    super.key,
    required this.child,
    this.loadingWidget,
    this.errorWidget,
    this.noConnectionWidget,
    this.textColor,
    this.function,
    this.offlineMessage = networkErrorMessage,
  });

  @override
  ConsumerState<CheckConnectionWidget> createState() =>
      _CheckConnectionWidgetState();
}

class _CheckConnectionWidgetState extends ConsumerState<CheckConnectionWidget> {
  bool hasCalled = false;

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(internetStatusProvider);

    return connection.when(
      data: (isConnected) {
        if (isConnected) {
          if (!hasCalled) {
            widget.function?.call();
            hasCalled = true;
          }
          return widget.child;
        } else {
          hasCalled = false; // Reset if disconnected again
          return widget.noConnectionWidget ??
              Center(
                child: ErrorMessageText(
                  message: widget.offlineMessage,
                  color: widget.textColor,
                ),
              );
        }
      },
      loading: () => Center(
        child: widget.loadingWidget ?? const CircularProgressIndicator(),
      ),
      error: (e, _) => Center(
        child:
            widget.errorWidget ??
            ErrorMessageText(
              message: "Error checking connection",
              color: widget.textColor,
            ),
      ),
    );
  }
}

Future<bool> checkConnectionNow() async {
  return await InternetConnection().hasInternetAccess;
}

final internetStatusProvider = StreamProvider<bool>((ref) {
  final internetChecker = InternetConnection();
  return internetChecker.onStatusChange.map((status) {
    debugPrint(status.toString());
    return status == InternetStatus.connected;
  });
});
