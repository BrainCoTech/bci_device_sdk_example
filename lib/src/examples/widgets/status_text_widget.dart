import 'package:flutter/material.dart';

class StatusText extends StatelessWidget {
  final String title;
  final String value;
  final bool highlighted;

  const StatusText(
      {Key? key,
      required this.title,
      required this.value,
      this.highlighted = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(
            height: 5,
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 10,
                  color: highlighted
                      ? Colors.orange
                      : Theme.of(context).primaryColor))
        ],
      ),
    );
  }
}
