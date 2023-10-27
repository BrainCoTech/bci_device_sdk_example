import 'package:flutter_easyloading/flutter_easyloading.dart';

class ToastManager {
  static void show(String text, {bool bottom = true}) {
    EasyLoading.showToast(text,
        toastPosition: bottom
            ? EasyLoadingToastPosition.center
            : EasyLoadingToastPosition.center);
  }
}
