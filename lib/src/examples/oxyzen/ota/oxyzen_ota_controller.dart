import 'dart:async';

import 'package:bci_device_sdk_example/logger.dart';
import 'package:bci_device_sdk_example/main.dart';
import 'package:liboxyz/liboxyz.dart';
import 'package:bci_device_sdk_example/src/examples/utils/toast.dart';

class OxyZenOtaController extends GetxController with StreamSubscriptionsMixin {
  final device = BciDeviceManager.bondDevice as OxyZenDevice;
  final newFirmwareAvailable = OxyZenDfu.newFirmwareAvailable.obs;
  final latestVersion = OxyZenDfu.latestVersion.obs;
  final latestVersionNrf = OxyZenDfu.latestVersionNrf.obs;
  final latestVersionPpg = OxyZenDfu.latestVersionPpg.obs;
  final nrfVersion = ''.obs;
  final ppgVersion = ''.obs;

  String get currentVersion =>
      OtaChangeLog.combineVersion(nrfVersion.value, ppgVersion.value);

  final otaState = OtaState.idle.obs;

  bool get isSuccess => otaState.value == OtaState.success;

  bool get isFailed => otaState.value == OtaState.failed;

  bool get isReady => otaState.value == OtaState.idle;

  bool get inOta =>
      otaState.value == OtaState.uploading ||
      otaState.value == OtaState.applying;

  bool get inOtaPpg => device.dfuHandler.inDfuCustomized; // in OTA PPG
  bool get inOtaNrf => device.dfuHandler.inDfuNordic; // in OTA Nordic

  bool get _btnEnabled =>
      isSuccess ||
      isFailed ||
      (isReady && device.isConnected && OxyZenDfu.newFirmwareAvailable);

  final btnEnabled = true.obs; // 升级按钮是否可用
  final otaProgress = 0.obs; // 0~1000
  final uploadSpeed = 0.0.obs; // K/s

  OxyZenOtaController() {
    BciDeviceProxy.instance.onDeviceInfo.listen((_) {
      _updateFirmwareVersion();
    }).subscribedBy(this);
    // _updateFirmwareVersion();
    // otaState.value = OtaState.idle;
  }

  @override
  void onClose() {
    loggerApp.i('OxyZenOtaController, onClose');
    clearSubscriptions();
    clearOtaSubscriptions();
    device.abortDfu();
    super.onClose();
  }

  /// 升级按钮进度，[0~1]
  double get btnProgress {
    return otaProgress.value.clamp(1, otaProgressMax) /
        otaProgressMax.toDouble();
  }

  String get btnText {
    final inOtaPpg = this.inOtaPpg;
    String text;
    switch (otaState.value) {
      case OtaState.uploading:
        text =
            '正在升级${inOtaPpg ? 'PPG模块' : ''}${(btnProgress * 100.0).toStringAsFixed(1)}%';
        break;
      case OtaState.uploadFinished:
      case OtaState.applying:
        text = '正在重启${inOtaPpg ? 'PPG模块' : ''}...';
        break;
      case OtaState.success:
        text = '升级成功';
        break;
      case OtaState.failed:
        text = '升级失败，请稍后再试';
        break;
      case OtaState.idle:
        text = '开始升级';
        break;
    }
    return text;
  }

  bool get canBack => otaState.value != OtaState.applying;

  bool back() {
    if (canBack) {
      Get.back();
      return true;
    }
    ToastManager.show('固件升级中，请耐心等待');
    return false;
  }

  final List<StreamSubscription> _otaSubscriptions = [];

  void clearOtaSubscriptions() {
    for (var subscription in _otaSubscriptions) {
      subscription.cancel();
    }
    _otaSubscriptions.clear();
  }

  Future startOta() async {
    loggerApp.i('startOta');
    if (isSuccess || isFailed) {
      _printState();
      back();
      return;
    }
    if (!isReady) {
      _printState();
      return;
    }
    if (!device.isConnected) {
      loggerApp.w('Device is disconnected');
      return;
    }
    if (device.batteryLevel < OxyZenDfu.batteryLevelThreshold) {
      loggerApp.w('device is low battery, batteryLevel=${device.batteryLevel}');
      ToastManager.show('请将设备充电至${OxyZenDfu.batteryLevelThreshold}%以上再开始升级');
      return;
    }
    clearOtaSubscriptions();
    device.dfuHandler.progressController.listen((e) {
      final index = e[0] as int;
      final total = e[1] as int;
      final model = e[2] as OtaProgress;
      loggerApp.i(
          'DFU: $index/$total, progress=${model.progress}, speed=${model.speed.toStringAsFixed(2)}K/s');
      uploadSpeed.value = model.speed;
      otaProgress.value =
          (1000.0 * (index - 1) / total + model.progress.toDouble() / total)
              .round()
              .clamp(0, 1000);
    }).addToList(_otaSubscriptions);
    device.dfuHandler.stateController.listen((e) {
      final index = e[0] as int;
      final total = e[1] as int;
      final state = e[2] as OtaState;
      loggerApp.i('DFU: $index/$total, state=${state.name}');
      switch (state) {
        case OtaState.success:
        case OtaState.failed:
          if (index < total) return;
          clearOtaSubscriptions();
          break;
        default:
          break;
      }
      otaState.value = state;
      btnEnabled.value = _btnEnabled;
    }).addToList(_otaSubscriptions);
    final ret = await device.startDfuAll(() {
      loggerApp.w('Device DFU onFinished');
    });
    if (!ret) clearSubscriptions();
  }

  void _updateFirmwareVersion() {
    OxyZenDfu.checkNewFirmware();
    latestVersion.value = OxyZenDfu.latestVersion;
    newFirmwareAvailable.value = OxyZenDfu.newFirmwareAvailable;
    btnEnabled.value = _btnEnabled;
    nrfVersion.value = device.nrfVersion;
    ppgVersion.value = device.ppgVersion;
    _printState();
  }

  void _printState() {
    loggerApp.i('otaState=${otaState.value}, $device\n'
        'ppgAvailable=${OxyZenDfu.ppgNewFirmwareAvailable}, ${ppgVersion.value} => ${OxyZenDfu.latestVersionPpg}\n'
        'nrfAvailable=${OxyZenDfu.nrfNewFirmwareAvailable}, ${nrfVersion.value} => ${OxyZenDfu.latestVersionNrf}');
  }
}
