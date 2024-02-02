import 'dart:async';

import 'package:logging/logging.dart' as logging;
import 'package:stack_trace/stack_trace.dart';
import 'package:bci_device_sdk/bci_device_sdk.dart';
import 'package:bci_device_nordic/bci_device_nordic.dart';

final loggerApp = Logger('App');

List<Logger> get appLoggers => [loggerApp];

class AppLogger {
  static bool _initialed = false;

  static Future init({logging.Level? level}) async {
    /// NOTE: When false, all hierarchical logging instead is merged in the root logger.
    hierarchicalLoggingEnabled = true;

    if (_initialed) return;
    _initialed = true;

    await BciDeviceLogger.init(onDeviceModuleInit: onDeviceModuleInit);
    final package = Trace.current().frames.first.package!;
    BciDeviceLogger.addSubscriptions([
      ...BleDeviceLogger.loggerSubscriptions,
      ...appLoggers.map((e) => e.listen(package: package)),
    ]);
    if (level != null) setLogLevel(level);
  }

  static void setLogLevel(logging.Level level) {
    BleDeviceLogger.setLogLevel(level);
    for (var e in appLoggers) {
      e.level = level;
    }
  }

  static void onDeviceModuleInit() {
    BciDeviceLogger.updateDeviceInfo();
    BciDeviceLogger.addSubscription(
        BciDeviceProxy.instance.onDeviceInfo.listen((_) async {
      BciDeviceLogger.updateDeviceInfo();
    }));
  }
}
