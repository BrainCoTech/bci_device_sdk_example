import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:bci_device_sdk_example/logger.dart';
import 'package:bci_device_sdk_example/main.dart';
import 'package:liboxyz/liboxyz.dart';
import 'package:mutex/mutex.dart';
import 'package:bci_device_sdk_example/src/examples/utils/toast.dart';

enum OtaState {
  idle,
  uploading,
  applying,
  success,
  failed,
  disconnected,
  uploadTimeout,
  applyTimeout
}

class OxyZenOtaController extends GetxController with StreamSubscriptionsMixin {
  static File? _ppgFile;
  static int _ppgFileCrc = 0;

  Uint8List? get ppgFileBytes => _ppgFileBytes;
  Uint8List? _ppgFileBytes;

  final newFirmwareAvailable = OxyZenDfu.newFirmwareAvailable.obs;
  final latestVersion = OxyZenDfu.latestVersion.obs;
  final latestVersionNrf = OxyZenDfu.latestVersionNrf.obs;
  final latestVersionPpg = OxyZenDfu.latestVersionPpg.obs;
  final nrfVersion = ''.obs;
  final ppgVersion = ''.obs;

  String get currentVersion =>
      OtaChangeLog.combineVersion(nrfVersion.value, ppgVersion.value);

  bool get _btnEnabled => otaState.value == OtaState.success || _otaAvailable;
  final btnEnabled = true.obs; // 升级按钮是否可用

  bool get inOta =>
      otaState.value == OtaState.uploading ||
      otaState.value == OtaState.applying;

  bool get inReady => otaState.value != OtaState.success && !inOta;

  bool get success => otaState.value == OtaState.success;

  final otaState = OtaState.idle.obs;
  final otaProgress = 0.obs; // 0~1000
  final uploadRate = 0.obs; // K/s
  Timer? _uploadRateTimer;

  bool _updateAll = false; // OTA nRF then PPG
  bool _inOtaPpg = false; // in OTA PPG
  bool _waitOtaPpg = false; // wait to OTA PPG

  final bluetoothRadio = BleScanner.bluetoothState.value.obs;
  final bool showUploadRate;

  OxyZenOtaController({this.showUploadRate = false}) {
    _updateFirmwareVersion();
    final device = BciDeviceManager.bondDevice;
    if (device is OxyZenDevice) {
      device.resetOta();
      device.onDeviceInfo.listen((_) {
        _updateFirmwareVersion();

        // nRF模块升级完，检查是否继续升级PPG模块
        if (!_inOtaPpg &&
            _updateAll &&
            _waitOtaPpg &&
            OxyZenDfu.ppgNewFirmwareAvailable) {
          _waitOtaPpg = false;
          _inOtaPpg = true;
          _startDfu();
        }
      }).addToList(subscriptions);
    }

    BleScanner.bluetoothState.stream.listen((state) {
      bluetoothRadio.value = state;
      if (otaState.value == OtaState.uploading ||
          otaState.value == OtaState.applying) {
        _onStateChanged(OtaState.disconnected);
      }
    }).addToList(subscriptions);

    loggerApp.i('otaState=${otaState.value}, _otaAvailable=$_otaAvailable\n'
        'ppgAvailable=${OxyZenDfu.ppgNewFirmwareAvailable}, ${ppgVersion.value} => ${OxyZenDfu.latestVersionPpg}\n'
        'nrfAvailable=${OxyZenDfu.nrfNewFirmwareAvailable}, ${nrfVersion.value} => ${OxyZenDfu.latestVersionNrf}');
    btnEnabled.value = _btnEnabled;
    BciDeviceProxy.instance.onDeviceConnected.listen((connected) {
      if (connected) {
        _updateFirmwareVersion();
      } else {
        if (_inOtaPpg &&
            (otaState.value == OtaState.uploading ||
                otaState.value == OtaState.applying)) {
          _onStateChanged(OtaState.disconnected);
        }
      }
      btnEnabled.value = _btnEnabled;
    }).addToList(subscriptions);
  }

  @override
  void onClose() {
    super.onClose();
    loggerApp.i('DeviceOtaController, onClose');
    // debugPrintStack();
    clearSubscriptions();
    _clearOtaSubscriptions();
    final device = BciDeviceManager.bondDevice;
    if (device is OxyZenDevice) {
      device.resetOta();
    }
  }

  static const otaBatteryLevelThreshold = 15;

  bool get _otaAvailable =>
      otaState.value == OtaState.idle &&
      BciDeviceProxy.instance.state.isConnected &&
      OxyZenDfu.newFirmwareAvailable;

  bool get otaAvailable =>
      BciDeviceProxy.instance.batteryLevel >= otaBatteryLevelThreshold &&
      _otaAvailable;

  /// 升级按钮进度，[0, 1]
  double get btnProgress {
    return otaProgress.value.clamp(1, 1000) / 1000.0;
  }

  String get btnText {
    String text;
    switch (otaState.value) {
      case OtaState.uploading:
        text =
            '正在升级${_inOtaPpg && _updateAll ? 'PPG模块' : ''}${(btnProgress * 100.0).toStringAsFixed(_inOtaPpg ? 1 : 0)}%';
        break;
      case OtaState.applying:
        text = '正在重启${_inOtaPpg && _updateAll ? 'PPG模块' : ''}...';
        break;
      case OtaState.success:
        text = '升级成功';
        break;
      case OtaState.disconnected:
        text = '升级失败，请检查设备状态';
        break;
      case OtaState.applyTimeout:
      case OtaState.uploadTimeout:
      case OtaState.failed:
        text = '升级失败，请稍后再试';
        break;
      case OtaState.idle:
        text = '开始升级';
        break;
    }
    return text;
  }

  bool get canBack =>
      otaState.value != OtaState.uploading &&
      otaState.value != OtaState.applying;

  bool back() {
    if (canBack) {
      Get.back();
      return true;
    }
    ToastManager.show('固件升级中，请耐心等待');
    return false;
  }

  final _mutex = Mutex();

  Future startOta(
      {bool force = false, bool ppg = false, bool all = true}) async {
    if (otaState.value != OtaState.idle) {
      loggerApp.w('otaState=${otaState.value}');
      if (otaState.value == OtaState.success) back();
      return;
    }
    final device = BciDeviceManager.bondDevice;
    if (device is OxyZenDevice && device.otaStatus != OtaStatus.idle) {
      loggerApp.w('device otaStatus=${device.otaStatus}');
      return;
    }
    if (!BciDeviceProxy.instance.state.isConnected) {
      loggerApp.w('Device is disconnected');
      return;
    }
    if (BleScanner.bluetoothState.value != BluetoothState.on) {
      loggerApp.w('BluetoothState is off');
      return;
    }
    loggerApp.i('startOta');
    await _mutex.protect(() => _startOta(force: force, ppg: ppg, all: all));
  }

  /// 1、OTA nRF
  /// 2、OTA PPG
  Future _startOta(
      {bool force = false, bool ppg = false, bool all = true}) async {
    loggerApp.i('startOta, ppg=$ppg');
    if (!(await OxyZenDfu.isFileReady)) {
      return;
    }

    final device = BciDeviceManager.bondDevice;
    if (device is! OxyZenDevice || device.inDfu) return;

    if (otaState.value == OtaState.success) {
      loggerApp.w('otaState already success');
      back();
      return;
    }

    if (device.batteryLevel < otaBatteryLevelThreshold) {
      loggerApp.w('device is low battery, batteryLevel=${device.batteryLevel}');
      ToastManager.show('请将设备充电至$otaBatteryLevelThreshold%以上再开始升级');
      return;
    }
    if (!otaAvailable) {
      loggerApp.w('otaAvailable=false');
      return;
    }

    loggerApp.i('_startOta, ppg=$ppg, all=$all');
    _waitOtaPpg = false;
    _updateAll = all &&
        OxyZenDfu.nrfNewFirmwareAvailable &&
        OxyZenDfu.ppgNewFirmwareAvailable;
    _inOtaPpg = !OxyZenDfu.nrfNewFirmwareAvailable;
    await _startDfu();
  }

  Future _startDfu() async {
    final changeLog = OxyZenDfu.changeLog;
    if (changeLog == null) {
      loggerApp.w('changeLog == null');
      return;
    }
    final model = _inOtaPpg ? changeLog.ppg : changeLog.nordic;
    if (model == null) {
      loggerApp.w('model == null');
      return;
    }
    final firmwareUrl = model.url;
    final latestVersion = model.latestVersion;
    loggerApp.i('_startDfu, ${_inOtaPpg ? 'PPG' : 'nRF'} '
        'latestVersion=$latestVersion, firmwareUrl=$firmwareUrl');
    if (!firmwareUrl.isURL) {
      /// 升级地址有误
      loggerApp.w('firmwareUrl invalid');
      _onStateChanged(OtaState.failed);
      return;
    }

    final file = await FileCacheManager.getSingleFile(firmwareUrl);
    final filePath = file.path;
    loggerApp.i('filePath=$filePath');
    _onStateChanged(OtaState.uploading);
    if (_inOtaPpg) {
      // OTA PPG
      await _getPpgFileCrc(file);
      await _startOtaPpg(latestVersion);
    } else {
      // OTA nRF
      final device = BciDeviceManager.bondDevice;
      if (device is OxyZenDevice) {
        await _listenOtaStatus();
        device.startDfu(filePath);
      }
    }
  }

  Future _getPpgFileCrc(File file) async {
    if (_ppgFile != file || _ppgFile == null || _ppgFileBytes == null) {
      final bytes = await file.readAsBytes();
      // confirm time cost, crc VS md5
      loggerApp.i('bytes, len=${bytes.lengthInBytes}');
      _ppgFile = file;
      _ppgFileBytes = bytes;
      _ppgFileCrc = CRC16.modbus(bytes);
      loggerApp.i('_ppgFileCrc=$_ppgFileCrc');
    }
  }

  Future<void> _startOtaPpg(String firmwareVersion) async {
    if (_ppgFileBytes == null) return;
    final buffer = _ppgFileBytes!.buffer;
    final totalLength = buffer.lengthInBytes;

    loggerApp.i('_startOtaPpg');
    OxyZenDevice.getOtaFileDataCallback = (int offset, int sliceSize) async {
      if (_ppgFileBytes == null) return BciFile(success: false);
      // loggerApp.i('otaFile, totalLength=$totalLength, offset=$offset');
      if (offset > totalLength) return BciFile(success: false);
      if (offset == totalLength) {
        return BciFile(
          success: true,
          totalLength: totalLength,
          progress: 1.0,
        );
      }
      final finished = (offset + sliceSize) >= totalLength;
      final data = Uint8List.view(buffer, offset, finished ? null : sliceSize);
      final len = data.length;
      OxyZenDevice.receivedOtaFileSize += len;
      final progress = (offset + len.toDouble()) / totalLength.toDouble();
      return BciFile(
        success: true,
        data: data,
        totalLength: totalLength,
        progress: progress,
      );
    };

    final device = BciDeviceManager.bondDevice;
    if (device is! OxyZenDevice) return;
    await _listenOtaStatus();

    final bytes = _ppgFileBytes!;
    await device.startOtaPpg(
      version: firmwareVersion,
      crc: _ppgFileCrc,
      fileSize: bytes.lengthInBytes,
      frame: bytes.sublist(0, 76),
    );
  }

  void _onOtaPpgUploading() {
    if (!_inOtaPpg) return;
    _otaUploadTimeout?.cancel();
    _otaUploadTimeout = Timer(const Duration(seconds: 30), () {
      loggerApp.i('ppg ota upload timeout');
      _otaUploadTimeout?.cancel();
      _otaUploadTimeout = null;
      _onStateChanged(OtaState.uploadTimeout);
      _exitOta();
    });
  }

  void _onOtaPpgApply() {
    if (!_inOtaPpg) return;
    _otaUploadTimeout?.cancel();
    _otaUploadTimeout = null;
    _otaApplyTimeout?.cancel();
    _otaApplyTimeout = Timer(const Duration(seconds: 120), () {
      loggerApp.i('ppg ota apply timeout');
      _otaApplyTimeout?.cancel();
      _otaApplyTimeout = null;
      _onStateChanged(OtaState.applyTimeout);
      _exitOta();
    });
  }

  void _exitOta() async {
    final device = BciDeviceManager.bondDevice;
    if (device is! OxyZenDevice) return;
    await device.exitOta();
  }

  void _onStateChanged(OtaState state) {
    if (otaState.value == state) return;

    if (state == OtaState.success ||
        state == OtaState.failed ||
        state == OtaState.disconnected ||
        state == OtaState.uploadTimeout ||
        state == OtaState.applyTimeout) {
      _clearOtaSubscriptions();
    }
    otaState.value = state;
    if (btnEnabled.value) btnEnabled.value = false;
  }

  StreamSubscription? _ppgProgressSubscription;
  StreamSubscription? _ppgStatusSubscription;
  Timer? _otaUploadTimeout;
  Timer? _otaApplyTimeout;

  void _clearOtaSubscriptions() {
    _uploadRateTimer?.cancel();
    _uploadRateTimer = null;
    _otaApplyTimeout?.cancel();
    _otaApplyTimeout = null;
    _otaUploadTimeout?.cancel();
    _otaUploadTimeout = null;
    _ppgProgressSubscription?.cancel();
    _ppgProgressSubscription = null;
    _ppgStatusSubscription?.cancel();
    _ppgStatusSubscription = null;
  }

  Future _listenOtaStatus() async {
    final device = BciDeviceManager.bondDevice;
    if (device is! OxyZenDevice) return;

    if (showUploadRate && _inOtaPpg) {
      OxyZenDevice.receivedOtaFileSize = 0;
      _uploadRateTimer?.cancel();
      _uploadRateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        uploadRate.value = OxyZenDevice.receivedOtaFileSize;
        debugPrint('uploadRate=${uploadRate.value}');
        OxyZenDevice.receivedOtaFileSize = 0;
      });
    }

    await _ppgProgressSubscription?.cancel();
    _ppgProgressSubscription = device.otaProgressController.listen((progress) {
      if ((progress < 50 && progress % 5 == 0) || progress % 50 == 0) {
        loggerApp.i('PPG OTA progress=$progress');
      }
      if (_updateAll) {
        if (_inOtaPpg) {
          otaProgress.value = (progress * 0.5).toInt() + 500;
        } else {
          otaProgress.value = (progress * 0.5).toInt();
        }
      } else {
        otaProgress.value = progress;
      }
      if (_inOtaPpg) _onOtaPpgUploading();
    });

    await _ppgStatusSubscription?.cancel();
    _ppgStatusSubscription = device.otaStatusController.listen((status) async {
      if (otaState.value != OtaState.uploading) {
        loggerApp.i('${_inOtaPpg ? 'PPG' : 'nRF'} OTA status=$status');
      }
      switch (status) {
        case OtaStatus.idle:
          break;
        case OtaStatus.uploading:
          _onStateChanged(OtaState.uploading);
          break;
        case OtaStatus.uploadFinished:
        case OtaStatus.applying:
          _uploadRateTimer?.cancel();
          _uploadRateTimer = null;
          _onStateChanged(OtaState.applying);
          if (_inOtaPpg) _onOtaPpgApply();
          break;
        case OtaStatus.success:
          _clearOtaSubscriptions();
          if (_inOtaPpg) {
            _updateAll = false;
          } else if (_updateAll && OxyZenDfu.ppgNewFirmwareAvailable) {
            _waitOtaPpg = true;
          }
          if (!_waitOtaPpg) _onStateChanged(OtaState.success);
          break;
        case OtaStatus.failed:
          _onStateChanged(OtaState.failed);
          break;
        default:
          break;
      }
    });
  }

  void _updateFirmwareVersion() {
    OxyZenDfu.checkNewFirmware();
    latestVersion.value = OxyZenDfu.latestVersion;
    newFirmwareAvailable.value = OxyZenDfu.newFirmwareAvailable;
    btnEnabled.value = _btnEnabled;
    final device = BciDeviceManager.bondDevice;
    if (device is! OxyZenDevice) return;
    nrfVersion.value = device.nrfVersion;
    ppgVersion.value = device.ppgVersion;
  }
}

class DeviceLocalOtaController extends OxyZenOtaController {
  final bool isLocal;
  final localFilePath = ''.obs; // OTA local filePath

  DeviceLocalOtaController({this.isLocal = false, String? localPath})
      : super() {
    if (localPath != null) localFilePath.value = localPath;
  }
}
