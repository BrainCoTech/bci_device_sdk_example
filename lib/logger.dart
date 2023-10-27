import 'dart:async';

import 'package:logging/logging.dart' as logging;
import 'package:stack_trace/stack_trace.dart';
import 'package:bci_device_sdk/bci_device_sdk.dart';

final loggerApp = Logger('App');

List<Logger> get appLoggers => [loggerApp];

class AppLogger {
  static bool _initialed = false;

  static Future init({logging.Level? level}) async {
    /// NOTE: When false, all hierarchical logging instead is merged in the root logger.
    hierarchicalLoggingEnabled = true;

    if (_initialed) return;
    _initialed = true;

    final package = Trace.current().frames.first.package!;
    await BciDeviceLogger.init(
        loggers: appLoggers,
        package: package,
        level: level,
        onDeviceModuleInit: onDeviceModuleInit);
  }

  static void onDeviceModuleInit() {
    BciDeviceLogger.updateDeviceInfo();
    BciDeviceLogger.subscriptions
        .add(BciDeviceProxy.instance.onDeviceInfo.listen((_) async {
      BciDeviceLogger.updateDeviceInfo();
    }));
  }
}
