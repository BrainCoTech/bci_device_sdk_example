import 'package:bci_device_sdk_example/main.dart';

class MultiDevicesController extends GetxController
    with StreamSubscriptionsMixin {
  final manager = Rx<MultiDeviceManager?>(null);

  @override
  void onInit() async {
    super.onInit();
    await MultiDeviceManager.init();
    manager.value = MultiDeviceManager.instance!;
  }

  @override
  void onClose() async {
    MultiDeviceManager.dispose();
    super.onClose();
  }
}
