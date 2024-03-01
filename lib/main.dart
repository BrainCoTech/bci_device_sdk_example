import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_utils/flutter_utils.dart' as utils;
import 'package:get/get.dart';
import 'package:libcmsn/libcmsn.dart';
import 'package:liboxyz/liboxyz.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:bci_device_sdk/bci_device_sdk.dart';
import 'package:bci_device_sdk_example/src/examples/constants/constant.dart';

import 'logger.dart';
import 'src/examples/crimson/crimson_device_screen.dart';
import 'src/examples/scan/ble_scan_screen.dart';
import 'src/examples/multi_devices/multi_devices_screen.dart';
import 'src/examples/oxyzen/oxyzen_device_screen.dart';
import 'src/examples/widgets/app_bar.dart';
export 'package:bci_device_sdk/bci_device_sdk.dart';
export 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init(level: Level.INFO);
  /// register device plugin
  await BciDevicePluginRegistry.init({
    CrimsonPluginRegistry(), // comment this if not use Crimson
    OxyZenPluginRegistry(), // comment this if not use OxyZen
  });
  /// register data mode
  BciDeviceConfig.setAvailableModes({
    BciDeviceDataMode.attention, // comment this if not use
    BciDeviceDataMode.meditation, // comment this if not use
    BciDeviceDataMode.social, // comment this if not use
    BciDeviceDataMode.drowsiness, // comment this if not use
    BciDeviceDataMode.eeg, // comment this if not use
    BciDeviceDataMode.ppg, // comment this if not use
  });
  loggerApp.i('------------------main, init------------------');
  loggerApp.i('-----cmsn version=${CrimsonFFI.sdkVersion}-----');
  loggerApp.i('-----oxyz version=${OxyZenFFI.sdkVersion}-----');
  await BciDeviceManager.init();

  loggerApp.i('------------------main, runApp--------------');
  utils.Devices.init();
  runApp(const MyApp());
  configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.threeBounce
    ..indicatorSize = 45
    ..radius = 10
    ..progressColor = ColorExt.primaryColor
    ..backgroundColor = ColorExt.primaryColor
    ..indicatorColor = ColorExt.primaryColor
    ..textColor = ColorExt.primaryColor
    ..maskColor = ColorExt.primaryColor.withOpacity(0.5)
    ..userInteractions = false
    ..dismissOnTap = false;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: HomeScreen(),
      builder: EasyLoading.init(),
      // routes: routes,
    );
  }
}

// Register the RouteObserver as a navigation observer.
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class HomeScreen extends StatelessWidget {
  final controller = Get.put(HomeScreenController());

  void _pushBondHeadbandScreen() {
    final headband = BciDeviceManager.bondDevice;
    if (headband == null) return;
    if (headband.isOxyzen) {
      Get.to(() => OxyZenDeviceScreen());
    } else if (headband.isCrimson || headband.isBstar) {
      Get.to(() => CrimsonDeviceScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        centerTitle: false,
        back: false,
        rxTitle: controller.buildInfo,
      ),
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Wrap(
            spacing: 15,
            children: <Widget>[
              if (BciDeviceConfig.supportBle)
                _button('BLE Device', () async {
                  if (BciDeviceManager.bondDevice != null) {
                    loggerApp.i('bondDevice=${BciDeviceManager.bondDevice}');
                    _pushBondHeadbandScreen();
                  } else {
                    await Get.to(() => BciDeviceScanScreen());
                  }
                }),
              _button('Multi Devices', () async {
                await Get.to(() => MultiDevicesScreen());
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreenController extends GetxController {
  static const demoTitle = '脑电设备DEMO';
  final buildInfo = demoTitle.obs;

  @override
  void onInit() async {
    final packageInfo = await PackageInfo.fromPlatform();
    buildInfo.value =
        '$demoTitle V${packageInfo.version}+${packageInfo.buildNumber}';
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
    BciDeviceManager.dispose();
  }
}

Widget _button(String text, VoidCallback onPressed) {
  return ElevatedButton(
    onPressed: onPressed,
    child: Text(text),
  );
}

///back事件响应阈值
const int _exitAppThreshold = 2000;
int? _popTimestamp;

Future<bool> _onWillPop() async {
  if (Platform.isAndroid) {
    if (_popTimestamp != null &&
        DateTime.now().millisecondsSinceEpoch - _popTimestamp! <
            _exitAppThreshold) {
      await BciDeviceManager.dispose();
      return true;
    } else {
      _popTimestamp = DateTime.now().millisecondsSinceEpoch;
      loggerApp.i('再按一次退出');
      // ToastProvider.instance.show('再按一次退出');
      return false;
    }
  } else {
    await BciDeviceManager.dispose();
    return true;
  }
}
