import 'package:flutter/material.dart';

import 'package:bci_device_sdk/bci_device_sdk.dart';
import 'package:get/get.dart';

import '../widgets/app_bar.dart';
import 'ble_scan_controller.dart';
import 'scan_result_tile.dart';

class BciDeviceScanScreen extends StatelessWidget {
  BciDeviceScanScreen({Key? key}) : super(key: key);
  final controller = Get.put(BleScanController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.permission.value.isOn
        ? const _FindDeviceScreen()
        : _BluetoothOffScreen(permission: controller.permission.value));
  }
}

class _BluetoothOffScreen extends StatelessWidget {
  final BciAppPermission permission;

  const _BluetoothOffScreen({Key? key, required this.permission})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(title: 'Find Crimson or OxyZen'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              permission == BciAppPermission.bluetooth
                  ? Icons.bluetooth_disabled
                  : Icons.location_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              permission.isOn
                  ? 'BLE permission is on'
                  : '${permission.name} not available',
              style: Theme.of(context)
                  .primaryTextTheme
                  .titleMedium!
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _FindDeviceScreen extends StatelessWidget {
  const _FindDeviceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(title: 'Find Crimson or OxyZen'),
      body: RefreshIndicator(
        onRefresh: () async => await BleScanner.instance.startScan(),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<ScanResult>>(
                stream: BleScanner.instance.onFoundDevices,
                initialData: BleScanner.instance.scanResults,
                builder: (c, snapshot) {
                  final devices = snapshot.data;
                  if (devices != null && devices.isNotEmpty) {
                    return IntrinsicHeight(
                        child: Column(
                            children: devices
                                .map((r) => ScanResultWidget(r, context))
                                .toList()));
                  } else {
                    return const Center(child: Text('未找到设备，请确认设备处于配对状态'));
                  }
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: BleScanner.instance.onScanningChanged,
        initialData: BleScanner.instance.isScanning,
        builder: (c, snapshot) {
          if (snapshot.data == true) {
            return FloatingActionButton(
              onPressed: () async => await BleScanner.instance.stopScan(),
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            );
          } else {
            return FloatingActionButton(
                onPressed: () async => await BleScanner.instance.startScan(),
                child: const Icon(Icons.search));
          }
        },
      ),
    );
  }
}
