import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:libcmsn/libcmsn.dart';
import 'package:bci_device_sdk/bci_device_sdk.dart';
import 'package:bci_device_sdk_example/src/examples/charts/attention_chart.dart';
import 'package:bci_device_sdk_example/src/examples/charts/eeg_chart.dart';
import 'package:bci_device_sdk_example/src/examples/charts/imu_chart.dart';
import 'package:bci_device_sdk_example/src/examples/widgets/segment.dart';

import '../oxyzen/oxyzen_device_controller.dart';
import '../widgets/app_bar.dart';
import '../widgets/status_text_widget.dart';
import 'crimson_device_controller.dart';

class CrimsonDeviceScreen extends StatelessWidget {
  final controller = Get.put(CrimsonDeviceController());

  CrimsonDeviceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Get.theme.colorScheme.inversePrimary,
          leading: const MyBackButton(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Obx(() => Text(
                  '${controller.deviceName.value} V${controller.firmware.value}')),
              const SizedBox(height: 3),
              Text(
                BciDeviceProxy.instance.id,
                style: TextStyle(fontSize: 14),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await BciDeviceManager.unbind();
                Get.back();
              },
              child: Text('解除配对'),
            ),
          ]),
      body: CrimsonDataWidget(),
    );
  }
}

class CrimsonDataWidget extends StatefulWidget {
  const CrimsonDataWidget({Key? key}) : super(key: key);

  @override
  State<CrimsonDataWidget> createState() => _CrimsonDataWidgetState();
}

class _CrimsonDataWidgetState extends State<CrimsonDataWidget> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CrimsonDeviceController>();
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                StreamBuilder<BciDeviceState>(
                  initialData: BciDeviceProxy.instance.state,
                  stream: BciDeviceProxy.instance.onStateChanged,
                  builder: (context, snapshot) => StatusText(
                    title: '头环状态',
                    value: snapshot.data!.debugDescription,
                    highlighted: !snapshot.data!.isConnected,
                  ),
                ),
                StreamBuilder<int>(
                  initialData: BciDeviceProxy.instance.batteryLevel,
                  stream: BciDeviceProxy.instance.onBatteryLevelChanged,
                  builder: (context, snapshot) => StatusText(
                    title: '电量',
                    value: '${BciDeviceProxy.instance.batteryLevel}%',
                    highlighted: BciDeviceProxy.instance.batteryLevel <= 0,
                  ),
                ),
                StreamBuilder<String>(
                  initialData: '-',
                  stream: BciDeviceProxy.instance.onAttention
                      .map((value) => value.toStringAsFixed(1)),
                  builder: (context, snapshot) => StatusText(
                    title: 'Attention',
                    value: snapshot.data!,
                  ),
                ),
                StreamBuilder<String>(
                  initialData: '-',
                  stream: BciDeviceProxy.instance.onMeditation
                      .map((value) => value.toStringAsFixed(1)),
                  builder: (context, snapshot) => StatusText(
                    title: 'Meditation',
                    value: snapshot.data!,
                  ),
                ),
                StreamBuilder<String>(
                  initialData: '-',
                  stream: BciDeviceProxy.instance.onSocialEngagement
                      .map((value) => value.toStringAsFixed(1)),
                  builder: (context, snapshot) => StatusText(
                    title: 'SocialEngagement',
                    value: snapshot.data!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SegmentWidget(
                      segments: ['EEG', 'ACC', 'GYRO', '正念'].asMap(),
                      selectedIndex: controller.tabIndex),
                  const SizedBox(height: 10),
                  chartWidget(controller.tabIndex.value),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                onPressed: () async {
                  final device = BciDeviceManager.bondDevice;
                  if (device is! CrimsonDevice) return;
                  await device.startEEG();
                },
                child: const Text('Start EEG'),
              ),
              const SizedBox(width: 5),
              ElevatedButton(
                onPressed: () async {
                  final device = BciDeviceManager.bondDevice;
                  if (device is! CrimsonDevice) return;
                  await device.stopEEG();
                },
                child: const Text('Stop EEG'),
              ),
            ]),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                onPressed: () async {
                  final device = BciDeviceManager.bondDevice;
                  if (device is! CrimsonDevice) return;
                  await device.startIMU();
                },
                child: const Text('Start IMU'),
              ),
              const SizedBox(width: 5),
              ElevatedButton(
                onPressed: () async {
                  final device = BciDeviceManager.bondDevice;
                  if (device is! CrimsonDevice) return;
                  await device.stopIMU();
                },
                child: const Text('Stop IMU'),
              ),
            ]),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                onPressed: () async {
                  await Get.to(() => IMUChartScreen(
                      chartType: ChartType.gyro,
                      valuesX: controller.gyroX,
                      valuesY: controller.gyroY,
                      valuesZ: controller.gyroZ,
                      imuSeqNum: controller.imuSeqNum));
                },
                child: const Text('GYRO'),
              ),
              const SizedBox(width: 5),
              ElevatedButton(
                onPressed: () async {
                  await Get.to(() => IMUChartScreen(
                      chartType: ChartType.euler,
                      valuesX: controller.yaw,
                      valuesY: controller.pitch,
                      valuesZ: controller.roll,
                      imuSeqNum: controller.imuSeqNum));
                },
                child: const Text('Euler'),
              ),
            ]),
            const SizedBox(height: 20),
            Obx(() => Text(
                '${BciDeviceProxy.instance.name}   固件版本：V${controller.firmware.value}')),
            ElevatedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['zip', 'bin', 'ota'],
                );
                if (result != null) {
                  ConfigController.filePath.value =
                      result.files.single.path ?? '';
                } else {
                  // User canceled the picker
                }
              },
              child: const Text('Select Local File'),
            ),
            Obx(() => Text('FilePath: ${ConfigController.filePath.value}')),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    controller.startDFU();
                  },
                  child: const Text('startDFU'),
                ),
                const SizedBox(width: 5),
                Obx(() => controller.dfuProgress.value.isEmpty
                    ? SizedBox(width: 5)
                    : Text('DFU progress: ${controller.dfuProgress.value}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget chartWidget(int index) {
    final controller = Get.find<CrimsonDeviceController>();
    switch (index) {
      case 0:
        return EEGChartWidget(
          eegSeqNum: controller.eegSeqNum,
          eegValues: controller.eegValues,
        );
      case 1:
        return IMUChartWidget(
          chartType: ChartType.acc,
          imuSeqNum: controller.imuSeqNum,
          valuesX: controller.accX,
          valuesY: controller.accY,
          valuesZ: controller.accZ,
        );
      case 2:
        return IMUChartWidget(
          chartType: ChartType.acc,
          imuSeqNum: controller.imuSeqNum,
          valuesX: controller.gyroX,
          valuesY: controller.gyroY,
          valuesZ: controller.gyroZ,
        );
      default:
        return const MeditationChart();
    }
  }
}
