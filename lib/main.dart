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
export 'package:bci_device_sdk/bci_device_sdk.dart';
export 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BciDevicePluginRegistry.register(CrimsonPluginRegistry());
  BciDevicePluginRegistry.register(OxyZenPluginRegistry());
  await AppLogger.init(level: Level.ALL);
  BciDeviceConfig.setAvailableModes({
    BciDeviceDataMode.attention,
    BciDeviceDataMode.meditation,
    BciDeviceDataMode.drowsiness,
    BciDeviceDataMode.social,
    BciDeviceDataMode.stress,
    BciDeviceDataMode.eeg,
    BciDeviceDataMode.ppg,
    BciDeviceDataMode.imu,
  });
  loggerApp.i('------------------main, init------------------');
  loggerApp.i('-----cmsn version=${getCrimsonSDKVersion()}-----');
  loggerApp.i('-----oxyz version=${getOxyzenSDKVersion()}-----');
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
      home: const HomeScreen(),
      builder: EasyLoading.init(),
      // routes: routes,
    );
  }
}

// Register the RouteObserver as a navigation observer.
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final buildInfo = ''.obs;

  @override
  void initState() {
    super.initState();
    loggerApp.i('initState');
    Future.microtask(() async {
      final packageInfo = await PackageInfo.fromPlatform();
      buildInfo.value = 'V${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  void dispose() {
    loggerApp.i('dispose');
    BciDeviceManager.dispose();
    loggerApp.i('dispose done');

    super.dispose();
  }

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
      appBar: AppBar(
        title: Obx(() => Text('BCI Device DEMO $buildInfo')),
        backgroundColor: Colors.lightBlue,
      ),
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Wrap(
            spacing: 15,
            children: <Widget>[
              if (BciDeviceConfig.supportOxyZen)
                _button('OxyZen', () async {
                  loggerApp.i(BciDeviceManager.bondDevice);
                  if (BciDeviceManager.bondDevice != null) {
                    _pushBondHeadbandScreen();
                  } else {
                    await Get.to(() => const CrimsonScanScreen());
                  }
                }),
              if (BciDeviceConfig.supportCrimson)
                _button('Crimson', () async {
                  if (BciDeviceManager.bondDevice != null) {
                    _pushBondHeadbandScreen();
                  } else {
                    await Get.to(() => const CrimsonScanScreen());
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
