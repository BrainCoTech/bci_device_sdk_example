import 'package:charts_flutter_new/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'eeg_chart.dart';

final imuChartColors = [
  charts.MaterialPalette.red.shadeDefault,
  charts.MaterialPalette.green.shadeDefault,
  charts.MaterialPalette.blue.shadeDefault
];
const imuChartTitles = ['x', 'y', 'z'];
const eulerChartTitles = ['yaw', 'pitch', 'roll'];

class IMUChartScreen extends StatelessWidget {
  final ChartType chartType;
  final RxnInt imuSeqNum;
  final RxList<double> valuesX;
  final RxList<double> valuesY;
  final RxList<double> valuesZ;

  const IMUChartScreen({
    Key? key,
    required this.chartType,
    required this.imuSeqNum,
    required this.valuesX,
    required this.valuesY,
    required this.valuesZ,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('$chartType'),
        ),
        body: IMUChartWidget(
          chartType: chartType,
          imuSeqNum: imuSeqNum,
          valuesX: valuesX,
          valuesY: valuesY,
          valuesZ: valuesZ,
        ));
  }
}

class IMUChartWidget extends StatelessWidget {
  final ChartType chartType;
  final RxnInt imuSeqNum;
  final RxList<double> valuesX;
  final RxList<double> valuesY;
  final RxList<double> valuesZ;
  const IMUChartWidget({
    Key? key,
    required this.chartType,
    required this.imuSeqNum,
    required this.valuesX,
    required this.valuesY,
    required this.valuesZ,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          Row(
            children: imuChartTitles
                .asMap()
                .map((i, e) => MapEntry(
                    i,
                    Text(
                      e,
                      style: TextStyle(
                        color: covertColor(imuChartColors[i]),
                      ),
                    )))
                .values
                .toList(),
          ),
          SizedBox(height: 5),
          Text(
            'IMU SeqNum=${imuSeqNum.value}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 5),
          valuesX.isEmpty
              ? const Text('Empty Chart')
              : Container(
                  width: double.infinity,
                  height: 200,
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).primaryColor.withAlpha(0x15),
                  child: lineChart(),
                ),
        ],
      );
    });
  }

  Color covertColor(charts.Color color) =>
      Color.fromARGB(255, color.r, color.g, color.b);

  Widget lineChart() {
    final data = [valuesX, valuesY, valuesZ];
    final ids = [0, 1, 2]
        .map((e) => '${chartType.toString()}-${imuChartTitles[e]}')
        .toList();

    return charts.LineChart(
        [0, 1, 2]
            .map((e) => toImuSeries(data[e], ids[e], imuChartColors[e]))
            .toList(),
        animate: false);
  }
}

charts.Series<LinearValues, int> toImuSeries(
    List<double> data, String id, charts.Color color) {
  final list = <LinearValues>[];
  for (var i = 0; i < data.length; i++) {
    list.add(LinearValues(i, data[i]));
  }

  return charts.Series<LinearValues, int>(
    id: id,
    colorFn: (_, __) => color,
    domainFn: (LinearValues value, _) => value.x,
    measureFn: (LinearValues value, _) => value.y,
    data: list,
  );
}
