import 'package:flutter/material.dart';
import 'package:bci_device_sdk_example/logger.dart';
import 'package:bci_device_sdk_example/main.dart';

import '../scan/scan_result_tile.dart';
import '../widgets/app_bar.dart';
import '../widgets/status_text_widget.dart';
import 'multi_devices_controller.dart';

class MultiDevicesScreen extends StatelessWidget {
  MultiDevicesScreen({Key? key}) : super(key: key);
  final controller = Get.put(MultiDevicesController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final manager = controller.manager.value;
      if (manager == null) {
        return Scaffold(
          appBar: MyAppBar(title: 'Find Multi Devices'),
        );
      }
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Get.theme.colorScheme.inversePrimary,
          leading: const MyBackButton(),
          actions: [
            TextButton(
              onPressed: manager.bindScanResults,
              child: Text('bindAll'),
            ),
            TextButton(
              onPressed: manager.clearAllDevices,
              child: Text('disconnectAll'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder(
                stream: manager.deviceMapStream,
                initialData: manager.deviceMap,
                builder: (context, snapshot) {
                  var list = snapshot.data!.values;
                  return Column(
                    children: [
                      ...list.map(
                        (e) => DeviceTile(
                          device: e,
                          onTapUnbind: () {
                            loggerApp.i('removeDevice');
                            manager.removeDevice(e);
                          },
                          onTapConnect: () {
                            loggerApp.i('autoConnect');
                            e.autoConnect();
                          },
                        ),
                      )
                    ],
                  );
                },
              ),
              StreamBuilder<List<ScanResult>>(
                  stream: manager.scanResultsStream,
                  initialData: manager.scanResults,
                  builder: (c, snapshot) {
                    if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                      var list = snapshot.data as List<ScanResult>;
                      var results = list
                          .where(
                              (e) => !manager.deviceMap.containsKey(e.uniqueId))
                          .toList();
                      return IntrinsicHeight(
                        child: Column(
                          children: results.map((r) {
                            return ScanResultTile(
                              result: r,
                              onTap: () => manager.bindScanResult(r),
                            );
                          }).toList(),
                        ),
                      );
                    } else {
                      return const Center(child: Text('扫描设备列表为空'));
                    }
                  }),
            ],
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
    });
  }
}

class DeviceTile extends StatelessWidget {
  final VoidCallback onTapUnbind;
  final VoidCallback onTapConnect;

  const DeviceTile({
    Key? key,
    required this.device,
    required this.onTapUnbind,
    required this.onTapConnect,
  }) : super(key: key);

  final BciDevice device;

  Widget _buildTitle(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Text(
          device.name,
        ),
        const SizedBox(height: 5),
        Text(
          device.id.substring(device.id.length - 10),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildTitle(context),
            const SizedBox(width: 15),
            StreamBuilder<BciDeviceState>(
              initialData: device.state,
              stream: device.onStateChanged,
              builder: (context, snapshot) => StatusText(
                title: 'State',
                value: snapshot.data!.name,
              ),
            ),
            StreamBuilder<String>(
              initialData: '-',
              stream: device.onAttention
                  .map((attention) => attention.toStringAsFixed(1)),
              builder: (context, snapshot) => StatusText(
                title: 'Attention',
                value: snapshot.data!,
              ),
            ),
            ElevatedButton(
                onPressed: onTapConnect,
                child: Text(
                  '手动重连',
                  style: Theme.of(context)
                      .primaryTextTheme
                      .labelLarge!
                      .copyWith(color: Colors.white),
                )),
            SizedBox(width: 10),
            ElevatedButton(
                onPressed: onTapUnbind,
                child: Text(
                  '解除配对',
                  style: Theme.of(context)
                      .primaryTextTheme
                      .labelLarge!
                      .copyWith(color: Colors.white),
                )),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
