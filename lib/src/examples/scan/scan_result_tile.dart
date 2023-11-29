import 'package:bci_device_sdk_example/logger.dart';
import 'package:bci_device_sdk_example/src/examples/crimson/crimson_device_screen.dart';
import 'package:bci_device_sdk_example/src/examples/oxyzen/oxyzen_device_screen.dart';
import 'package:flutter/material.dart';
import 'package:bci_device_sdk/bci_device_sdk.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_utils/flutter_utils.dart';
import 'package:get/get.dart';

class ScanResultWidget extends StatelessWidget {
  final ScanResult result;
  final BuildContext ctx;

  const ScanResultWidget(this.result, this.ctx, {Key? key}) : super(key: key);

  String? getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    var res = <String>[];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ScanResultTile(
      result: result,
      onTap: () async {
        try {
          await EasyLoading.show(status: '配对中...');
          await BciDeviceManager.bindBleScanResult(result);
          await EasyLoading.showSuccess('配对成功!');
          await Get.off(() =>
              result.isOxyZen ? OxyZenDeviceScreen() : CrimsonDeviceScreen());
        } catch (e, st) {
          loggerApp.i('$e');
          debugPrintStack(stackTrace: st, maxFrames: 7);
          await EasyLoading.showError('配对失败');
          await BleScanner.instance.startScan(); //restart scan
        }
      },
    );
  }
}

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key? key, required this.result, required this.onTap})
      : super(key: key);

  final ScanResult result;
  final VoidCallback onTap;

  Widget _buildTitle(BuildContext context) {
    final name = result.localName;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          name.isEmpty ? 'N/A' : name,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          result.device.deviceId.substring(result.device.deviceId.length - 10),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontSize: 13.ratio),
        ),
      ],
    );
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String? getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    var res = <String>[];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String? getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    var res = <String>[];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final inPairingMode = result.inPairingMode;
    final batteryLevel = result.batteryLevel;
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: ElevatedButton(
        // color: Colors.black,
        // textColor: Colors.white,
        onPressed: (result.advertisementData.connectable) ? onTap : null,
        child: const Text('配对'),
      ),
      children: <Widget>[
        _buildAdvRow(
            context, 'Complete Local Name', result.advertisementData.localName),
        _buildAdvRow(context, 'batteryLevel', '$batteryLevel'),
        _buildAdvRow(context, 'inPairingMode', '$inPairingMode'),
        _buildAdvRow(
            context,
            'Service UUIDs',
            (result.advertisementData.serviceUuids.isNotEmpty)
                ? result.advertisementData.serviceUuids.join(', ').toUpperCase()
                : 'N/A'),
      ],
    );
  }
}
