import 'package:bci_device_sdk_example/src/examples/widgets/status_text_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bci_device_sdk_example/src/examples/charts/attention_chart.dart';
import 'package:bci_device_sdk_example/src/examples/charts/eeg_chart.dart';
import 'package:bci_device_sdk_example/src/examples/charts/imu_chart.dart';
import 'package:bci_device_sdk_example/src/examples/charts/ppg_chart.dart';
import 'package:bci_device_sdk_example/src/examples/oxyzen/ota/oxyzen_ota_screen.dart';
import 'package:bci_device_sdk_example/src/examples/widgets/segment.dart';
import 'package:liboxyz/liboxyz.dart';

import '../../../main.dart';
import '../widgets/app_bar.dart';
import 'oxyzen_device_controller.dart';

class OxyZenDeviceScreen extends StatelessWidget {
  final controller = Get.put(OxyzenDeviceController());

  OxyZenDeviceScreen({Key? key}) : super(key: key);

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
                  '${controller.deviceName.value} nRF_PPG:${controller.firmware.value}')),
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
                child: Text('解除配对')),
          ]),
      body: OxyzenDataWidget(),
    );
  }
}

class OxyzenDataWidget extends StatefulWidget {
  const OxyzenDataWidget({Key? key}) : super(key: key);

  @override
  State<OxyzenDataWidget> createState() => _OxyzenDataWidgetState();
}

class _OxyzenDataWidgetState extends State<OxyzenDataWidget> {
  final device = BciDeviceManager.bondDevice as OxyZenDevice;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OxyzenDeviceController>();
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(children: <Widget>[
              StreamBuilder<BciDeviceConnectivity>(
                initialData: device.connectivity,
                stream: device.onConnectivityChanged,
                builder: (context, snapshot) => StatusText(
                  title: 'Connectivity',
                  value: snapshot.data!.name,
                  highlighted: !snapshot.data!.isConnected,
                  // high
                ),
              ),
              StreamBuilder<BciDeviceContactState>(
                initialData: device.contactState,
                stream: device.onContactStateChanged,
                builder: (context, snapshot) => StatusText(
                  title: 'Contact',
                  value: snapshot.data!.name,
                  highlighted: !snapshot.data!.isContacted,
                ),
              ),
              if (!device.disableOrientationCheck)
                StreamBuilder<BciDeviceOrientation>(
                  initialData: BciDeviceProxy.instance.orientation,
                  stream: BciDeviceProxy.instance.onOrientationChanged,
                  builder: (context, snapshot) => StatusText(
                    title: 'Orientation',
                    value: snapshot.data!.name,
                    highlighted: snapshot.data != BciDeviceOrientation.normal,
                  ),
                ),
              StreamBuilder<PpgContactState>(
                initialData: PpgContactState.undetected,
                stream: BciDeviceProxy.instance.onRawPPGData
                    .map((e) => e.ppgContactState),
                builder: (context, snapshot) => StatusText(
                  title: 'PpgContactState',
                  value: snapshot.data!.toString(),
                  highlighted: snapshot.data!.index <
                      PpgContactState.onSomeSubject.index,
                ),
              ),
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
            ]),
            const SizedBox(height: 5),
            Row(
              children: <Widget>[
                StreamBuilder<String>(
                  initialData: BciDeviceProxy.instance.attention.toString(),
                  stream: BciDeviceProxy.instance.onAttention
                      .map((value) => value.toStringAsFixed(1)),
                  builder: (context, snapshot) => StatusText(
                    title: 'Attention',
                    value: snapshot.data!,
                  ),
                ),
                StreamBuilder<String>(
                  initialData: BciDeviceProxy.instance.attentionEOG.toString(),
                  stream: BciDeviceProxy.instance.onAttentionEOG
                      .map((value) => value.toStringAsFixed(1)),
                  builder: (context, snapshot) => StatusText(
                    title: 'Attention-EOG',
                    value: snapshot.data!,
                  ),
                ),
                StreamBuilder<String>(
                  initialData: BciDeviceProxy.instance.eyeMovement.toString(),
                  stream: BciDeviceProxy.instance.onEyeMovement
                      .map((value) => value.toStringAsFixed(1)),
                  builder: (context, snapshot) => StatusText(
                    title: '眼动指数',
                    value: snapshot.data!,
                  ),
                ),
                StreamBuilder<String>(
                  initialData: BciDeviceProxy.instance.meditation.toString(),
                  stream: BciDeviceProxy.instance.onMeditation
                      .map((value) => value.toStringAsFixed(1)),
                  builder: (context, snapshot) => StatusText(
                    title: '正念指数',
                    value: snapshot.data!,
                  ),
                ),
                StreamBuilder<String>(
                  initialData: BciDeviceProxy.instance.calmness.toString(),
                  stream: BciDeviceProxy.instance.onCalmness
                      .map((value) => value.toStringAsFixed(1)),
                  builder: (context, snapshot) => StatusText(
                    title: '平静指数',
                    value: snapshot.data!,
                  ),
                ),
                StreamBuilder<String>(
                  initialData: BciDeviceProxy.instance.awareness.toString(),
                  stream: BciDeviceProxy.instance.onAwareness
                      .map((value) => value.toStringAsFixed(1)),
                  builder: (context, snapshot) => StatusText(
                    title: '觉察指数',
                    value: snapshot.data!,
                  ),
                ),
                StreamBuilder<String>(
                  initialData: BciDeviceProxy.instance.drowsiness.toString(),
                  stream: BciDeviceProxy.instance.onDrowsiness
                      .map((value) => value.toStringAsFixed(1)),
                  builder: (context, snapshot) => StatusText(
                    title: '困倦指数',
                    value: snapshot.data!,
                  ),
                ),
                StreamBuilder<String>(
                  initialData: BciDeviceProxy.instance.stress.toString(),
                  stream: BciDeviceProxy.instance.onStress
                      .map((value) => value.toStringAsFixed(1)),
                  builder: (context, snapshot) => StatusText(
                    title: '压力指数',
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
                      segments:
                          // 'Focus'
                          BciDeviceManager.isBondOxyZen
                              ? ['EEG', 'ACC', 'GYRO', 'PPG', '指数'].asMap()
                              : ['EEG', 'ACC', 'GYRO', '指数'].asMap(),
                      selectedIndex: controller.tabIndex),
                  const SizedBox(height: 10),
                  chartWidget(controller.tabIndex.value),
                ],
              ),
            ),
            /*
            if (kDebugMode)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ElevatedButton(
                  onPressed: () async {
                    controller.analyzeEEG();
                  },
                  child: const Text('Analyze EEG'),
                ),
                const SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () async {
                    controller.pauseAnalyzeEEG();
                  },
                  child: const Text('Pause Analyze EEG'),
                ),
              ]),
             */
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                onPressed: () async {
                  await device.startEEG();
                },
                child: const Text('Start EEG'),
              ),
              const SizedBox(width: 5),
              ElevatedButton(
                onPressed: () async {
                  await device.stopEEG();
                },
                child: const Text('Stop EEG'),
              ),
              const SizedBox(width: 5),
              if (kDebugMode)
                ElevatedButton(
                  onPressed: () async {
                    await device.rename('Oxyzen-Yongle');
                  },
                  child: const Text('Rename'),
                ),
            ]),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                onPressed: () async {
                  await device.startIMU();
                },
                child: const Text('Start IMU'),
              ),
              const SizedBox(width: 5),
              ElevatedButton(
                onPressed: () async {
                  await device.stopIMU();
                },
                child: const Text('Stop IMU'),
              ),
            ]),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                onPressed: () async {
                  await device.startPPG();
                  // await device.zenliteConfigPpg(
                  //     sampleRate: zenlite_proto_common.PpgUR.PPG_UR1HZ,
                  //     ppgMode: zenlite_proto_common.PpgMode.PPG_MODE_SPO2);
                  // await device.zenliteConfigPpg(
                  //     sampleRate: zenlite_proto_common.PpgUR.PPG_UR1HZ,
                  //     ppgMode: zenlite_proto_common.PpgMode.PPG_MODE_RAW);
                },
                child: const Text('Start PPG'),
              ),
              const SizedBox(width: 5),
              ElevatedButton(
                onPressed: () async {
                  device.stopPPG();
                },
                child: const Text('Stop PPG'),
              ),
              const SizedBox(width: 5),
            ]),
            const SizedBox(height: 5),
            if (kDebugMode)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ElevatedButton(
                  onPressed: () async {
                    await device.setSleepIdleSeconds(30 * 60);
                  },
                  child: const Text('setSleepIdleSeconds'),
                ),
              ]),
            const SizedBox(height: 5),
            ElevatedButton(
              onPressed: () async {
                if (!BciDeviceManager.isBondOxyZen) return;
                await OxyZenDfu.checkNewFirmware(force: true);
                await Get.to(() => OxyZenOtaScreen());
              },
              child: const Text('Device OTA'),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Obx(() => Text(
                    '${BciDeviceProxy.instance.name}   固件版本：V${controller.firmware.value}')),
                Obx(() => Text('FilePath: ${ConfigController.filePath.value}')),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    const SizedBox(width: 5),
                    ElevatedButton(
                      onPressed: () async {
                        await controller.startDFU();
                      },
                      child: const Text('startDFU'),
                    ),
                    const SizedBox(width: 5),
                    Obx(() => controller.dfuProgress.value.isEmpty
                        ? SizedBox(width: 5)
                        : Text(
                            'DFU progress: ${controller.dfuProgress.value}')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget chartWidget(int index) {
    final controller = Get.find<OxyzenDeviceController>();
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
      case 3:
        return PpgChartWidget();
      default:
        return const MeditationChart();
    }
  }
}
