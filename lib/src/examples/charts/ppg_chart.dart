import 'package:charts_flutter_new/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bci_device_sdk/bci_device_sdk.dart';
import 'package:bci_device_sdk_example/src/examples/oxyzen/oxyzen_device_controller.dart';

import 'eeg_chart.dart';

const ppgChartColors = [Colors.red, Colors.green, Colors.blue];

class PpgChartWidget extends StatelessWidget {
  const PpgChartWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OxyzenDeviceController>();
    return Obx(
      () => Column(
        children: [
          Text(
            'PPG: ${controller.ppgData.toString()}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 5),
          // controller.ppgValues.isEmpty
          //     ? const Text('Empty Chart')
          //     : Container(
          //         width: double.infinity,
          //         height: 200,
          //         padding: const EdgeInsets.all(12),
          //         color: Theme.of(context).primaryColor.withAlpha(0x15),
          //         child: chart(controller.ppgValues),
          //       ),
        ],
      ),
    );
  }

  Widget chart(RxList<PpgRawModel> values) {
    return charts.LineChart(toPPGSeries(values), animate: false);
  }
}

List<charts.Series<LinearValues, int>> toPPGSeries(List<PpgRawModel> data) {
  final hrList = <LinearValues>[];
  for (var i = 0; i < data.length; i++) {
    hrList.add(LinearValues(i, data[i].hr.toDouble()));
  }
  final spO2List = <LinearValues>[];
  for (var i = 0; i < data.length; i++) {
    spO2List.add(LinearValues(i, data[i].spO2.toDouble()));
  }

  return [
    charts.Series<LinearValues, int>(
      id: 'PPG-HR',
      colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      domainFn: (LinearValues value, _) => value.x,
      measureFn: (LinearValues value, _) => value.y,
      data: hrList,
    ),
    charts.Series<LinearValues, int>(
      id: 'PPG-SpO2',
      colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
      domainFn: (LinearValues value, _) => value.x,
      measureFn: (LinearValues value, _) => value.y,
      data: spO2List,
    ),
  ];
}
