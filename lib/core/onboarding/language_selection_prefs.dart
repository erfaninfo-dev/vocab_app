import 'package:shared_preferences/shared_preferences.dart';

const String kUiLanguageSelectedKey = 'ui_language_selected_v1';

Future<bool> isUiLanguageSelected() async {
  final p = await SharedPreferences.getInstance();
  return p.getBool(kUiLanguageSelectedKey) ?? false;
}

Future<void> setUiLanguageSelected() async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(kUiLanguageSelectedKey, true);
}
