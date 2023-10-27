class ValidateUtil {
  /// 不能包含中文，逗号
  static bool validateWifiPwd(String text) {
    if (text.isEmpty) return false;

    /// \u4e00-\u9fa5
    final regExp = RegExp(r'([^\x00-\xff]|,)'); //双字节字符
    return !regExp.hasMatch(text);
  }
}
