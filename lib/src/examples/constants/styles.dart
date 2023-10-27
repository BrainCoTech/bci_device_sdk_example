import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:bci_device_sdk_example/src/examples/ui.dart';

class ColorExt {
  static const blurCardBg = Color(0x3DFEFFFE);
  static const blurCardBorder = Color(0x80F8F8F8);

  static const primaryColor = Color(0xFF0EA595);
  static const primaryColorDark = Color(0xFF4E6C6A);
  static const primaryColorLight = Color(0xFFFFDEB7);
  static const titleColor = Color(0xFF3D3D3D);
  static const descColor = Color(0x99000000);

  static const secondaryColorLightGrey = Color(0xFFD7D7D7);
  static const secondaryColorGrey = Color(0xFF999999);
  static const errorColor = Color(0xFFDD6767);

  //Text Color
  static const primaryTextColor = Color(0xFF333333);
  static const bodyTextColor = Color(0xFF7D7D7D);
  static const captionTextColor = Color(0xFF666666);
  static const dialogTextColor = Color(0xFF000000);

  //更新文字color和style
  static const rewardValueColor = Color(0xFFF75E36);
  static const rewardBgColor = Color(0xFF172B88);
  static const rewardButtonColor = Color(0xFFFF7747);

  static Color closeIconBgColor = Color(0xFF222222).withOpacity(0.59);

  static const alertColor = Color(0xFFE6A0A0);
  static const dividerColor = Color(0xFFEFEFEF);
  static const textColor = Color(0xFF818181);
  static const greyColor = Color(0xFFD8D8D8);
  static const deepGreyColor = Color(0xFF8D8D8D);
  static const reportBottomTip = Color(0xFF969CA3);
  static const toastBgColor = Color(0x804E6C6A);
  static const shadowColor = Color(0x1A000000);

  static const stepperGreen = Color(0xFF4DC591);
  static const placeholder = Color(0xFFF5F5F5);
  static const disabledHintColor = Color(0xFFA1A1A1);

  /// using
  /// [tools-for-picking-colors](https://material.io/design/color/the-color-system.html#tools-for-picking-colors)
  /// to generate swatch
  static const swatch = MaterialColor(0xFF69C2EE, <int, Color>{
    50: Color(0xFFE0F3F4),
    100: Color(0xFFB2E1E2),
    200: Color(0xFF7FCFCF),
    300: Color(0xFF69C2EE),
    400: Color(0xFF0FACAB),
    500: Color(0xFF009D99),
    600: Color(0xFF008F8B),
    700: Color(0xFF007F7A),
    800: Color(0xFF006F6A),
    900: Color(0xFF00534C),
  });
}

class Dimens {
  //常量
  static const bodyMultilineHeight = 20 / 14.0;
  static const dividerThick = 0.5;
  static const dividerIndent = 16.0;
  static const radius25 = 25.0;

  //字号
  static const trackerResultTextSize = 20.0;

  static const font_24 = 24.0;
  static const font_20 = 20.0;
  static const font_18 = 18.0;
  static const font_16 = 16.0;
  static const font_15 = 15.0;
  static const font_14 = 14.0;
  static const font_12 = 12.0;
  static const font_10 = 10.0;
}

class Styles {
  static ImageFilter cardBlur = ImageFilter.blur(
    sigmaX: 20,
    sigmaY: 20,
  );

  static ImageFilter cardBlurLight = ImageFilter.blur(
    sigmaX: 1,
    sigmaY: 1,
  );

  /// 大标题 30
  static final titleText = TextStyle(
    fontSize: 30.scale,
    color: ColorExt.titleColor,
    fontWeight: FontWeight.w500,
  );

  //大标题 20
  static const resultTitleStyle = TextStyle(
      fontSize: Dimens.font_20,
      color: Colors.white,
      fontWeight: FontWeight.w600); //白色

  //中标题 18
  //#333 w600
  static const subtitleText = TextStyle(
    fontSize: Dimens.font_18,
    color: ColorExt.primaryTextColor,
    fontWeight: FontWeight.w600,
  );

  //白色 w600
  static const subTitleTextInverse = TextStyle(
      fontSize: Dimens.font_18,
      color: Colors.white,
      fontWeight: FontWeight.w600);

  //#000 w600
  static const subtitleTextDialog = TextStyle(
    fontSize: Dimens.font_18,
    color: ColorExt.dialogTextColor,
    fontWeight: FontWeight.w600,
  );

  //主题色
  static const subtitleTextPrimary = TextStyle(
    fontSize: Dimens.font_18,
    color: ColorExt.primaryColor,
    fontWeight: FontWeight.w600,
  );

  //黑色 w600
  static const subtitle2Text = TextStyle(
    fontSize: Dimens.font_16,
    color: ColorExt.primaryTextColor,
    fontWeight: FontWeight.w600,
  );

  //白色
  static const subtitle2Inverse = TextStyle(
    fontSize: Dimens.font_16,
    color: Colors.white,
    fontWeight: FontWeight.w600,
  );

  //主题色
  static const subtitle2Primary = TextStyle(
    fontSize: Dimens.font_16,
    color: ColorExt.primaryColor,
    fontWeight: FontWeight.w600,
  );

  /// 中文本 14
  //黑色 w600
  static const body1Text = TextStyle(
    fontSize: Dimens.font_14,
    color: ColorExt.primaryTextColor,
    fontWeight: FontWeight.w600,
  );

  static const body1Content = TextStyle(
    fontSize: Dimens.font_14,
    color: ColorExt.bodyTextColor,
  );

  static const body1Dialog = TextStyle(
    fontSize: Dimens.font_14,
    color: ColorExt.dialogTextColor,
  );

  static const body1SecondaryText = TextStyle(
    fontSize: Dimens.font_14,
    color: ColorExt.captionTextColor,
  );

  //主题色 w600
  static const body1Primary = TextStyle(
    fontSize: Dimens.font_14,
    color: ColorExt.primaryColor,
    fontWeight: FontWeight.w600,
  );

  /// 小文本 12
  static const smallBodyText = TextStyle(
    fontSize: Dimens.font_12,
    color: ColorExt.titleColor,
  ); //黑色
  static const smallBodyTextPrimary = TextStyle(
    fontSize: Dimens.font_12,
    color: ColorExt.primaryColor,
  ); //主题色
  static const smallBodyTextInverse = TextStyle(
    fontSize: Dimens.font_12,
    color: Colors.white,
  ); // 白色
  static const smallBodyTextAlert = TextStyle(
    fontSize: Dimens.font_12,
    color: ColorExt.errorColor,
  ); //红色

  /// 解释文字/标签 10
  static const captionText =
      TextStyle(fontSize: Dimens.font_10, color: ColorExt.titleColor); // 黑色
  static const captionTextInverse =
      TextStyle(fontSize: Dimens.font_10, color: Colors.white); //白色
  static const captionTextPrimary =
      TextStyle(fontSize: Dimens.font_10, color: ColorExt.primaryColor); //主题色
  static const captionTextAlert =
      TextStyle(fontSize: Dimens.font_10, color: ColorExt.alertColor); //红色

  static const inputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
    focusColor: ColorExt.primaryColor,
  );
}

class Themes {
  static ImageFrameBuilder get imageFrameBuilder => (
        BuildContext context,
        Widget child,
        int? frame,
        bool wasSynchronouslyLoaded,
      ) {
        final placeholder = Container(color: ColorExt.primaryColorDark);
        return Stack(
          children: [
            placeholder,
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: wasSynchronouslyLoaded || frame != null ? 1 : 0,
                duration: const Duration(seconds: 2),
                curve: Curves.easeOut,
                child: child,
              ),
            ),
          ],
        );
      };

  // typography.dart
  // Flutter上默认的文本和字体知识点 https://www.jianshu.com/p/124a4674d67b
  static String get fontFamilyDefault => fontFamilyDefaultCN;
  static final String fontFamilyDefaultEN =
      Platform.isAndroid ? 'Roboto' : '.SF UI Text';
  static final String fontFamilyDefaultEN20 =
      Platform.isAndroid ? 'Roboto' : '.SF UI Display'; // > 20pt
  static final String fontFamilyDefaultCN = Platform.isAndroid
      ? 'Source Han Sans' // Noto
      : 'PingFang SC';
  static String? fontFamily;
  static Color? scaffoldBackgroundColor;
  static final appTheme = ThemeData(
    primaryColor: ColorExt.primaryColor,
    primaryColorLight: ColorExt.primaryColorLight,
    primarySwatch: ColorExt.swatch,
    scaffoldBackgroundColor: scaffoldBackgroundColor ?? Colors.white,
    dividerTheme: DividerThemeData(
      color: ColorExt.dividerColor,
      space: Dimens.dividerThick,
      thickness: Dimens.dividerThick,
      indent: Dimens.dividerIndent,
      endIndent: Dimens.dividerIndent,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      color: Colors.transparent,
      toolbarTextStyle:
          Styles.subtitleText.copyWith(color: ColorExt.titleColor),
      titleTextStyle: Styles.subtitleText.copyWith(color: ColorExt.titleColor),
      iconTheme:
          IconThemeData(size: 28, color: ColorExt.secondaryColorLightGrey),
    ),
    textTheme: TextTheme(
      displayLarge: Styles.titleText,
      titleMedium: Styles.subtitleText,
      titleSmall: Styles.body1Text,
      bodyLarge: Styles.smallBodyTextPrimary,
      bodyMedium: Styles.smallBodyText,
      bodySmall: Styles.captionText,
    ),
    primaryTextTheme: TextTheme(
      titleLarge: Styles.titleText,
      titleSmall: Styles.body1Text,
      bodyMedium: Styles.smallBodyTextPrimary,
      bodySmall: Styles.captionTextPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
        hintStyle: Styles.subtitle2Text
            .copyWith(color: ColorExt.secondaryColorLightGrey),
        border: UnderlineInputBorder(
            borderSide: BorderSide(width: Dimens.dividerThick))),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(ColorExt.primaryColor),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: MaterialStateProperty.all(0),
        backgroundColor: MaterialStateProperty.all(ColorExt.primaryColor),
      ),
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      // buttonColor: ColorExt.swatch,
      buttonColor: ColorExt.primaryColor,
      highlightColor: ColorExt.swatch,
      disabledColor: ColorExt.secondaryColorLightGrey,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
            shape: MaterialStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22))))),
    dialogTheme: DialogTheme(
      titleTextStyle: Styles.subtitleTextDialog,
      contentTextStyle: Styles.smallBodyText,
    ),
    iconTheme: IconThemeData(color: ColorExt.primaryColor, size: 22),
    popupMenuTheme: PopupMenuThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(12),
        ),
      ),
    ),
    tabBarTheme: TabBarTheme(
        labelStyle: Styles.subtitleText,
        labelColor: ColorExt.primaryColor,
        unselectedLabelStyle: Styles.subtitleText,
        unselectedLabelColor: ColorExt.textColor,
        labelPadding: EdgeInsets.all(0)),
  );
}
