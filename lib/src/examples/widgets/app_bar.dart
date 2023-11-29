import 'package:flutter/material.dart';
import 'package:flutter_utils/flutter_utils.dart';
import 'package:get/get.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final RxString? rxTitle;
  final Widget? leading;
  final bool? centerTitle;
  final bool back;

  const MyAppBar({
    Key? key,
    this.title,
    this.rxTitle,
    this.leading,
    this.centerTitle = true,
    this.back = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: rxTitle != null
          ? Obx(() => _titleWidget(rxTitle!.value))
          : title != null
              ? _titleWidget(title!)
              : null,
      // backgroundColor: Get.theme.primaryColor,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      leading: leading ?? (back ? const MyBackButton() : null),
      centerTitle: centerTitle,
    );
  }

  Widget _titleWidget(String title) => Text(
        title,
        style: Get.textTheme.headlineSmall?.copyWith(color: Colors.white),
      );

  @override
  Size get preferredSize => AppBar().preferredSize;
}

///通用back按钮
class MyBackButton extends StatelessWidget {
  final Color? color;
  final VoidCallback? onPressed;

  const MyBackButton({
    super.key,
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (Navigator.canPop(context)) {
      return Padding(
        padding: const EdgeInsets.only(left: 2.0),
        child: IconButton(
          onPressed: onPressed ?? Get.back,
          iconSize: 24.ratio,
          icon: Icon(
            Icons.chevron_left,
            // Icons.arrow_back_ios,
            color: color ?? Colors.white,
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}
