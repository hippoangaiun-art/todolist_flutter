import 'package:shared_preferences/shared_preferences.dart';

class PrefField<T> {
  final String key;
  final T defaultValue;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  PrefField(this.key, this.defaultValue);

  Future<T> get value async {
    final prefs = await _prefs;
    if (T == String) return (prefs.getString(key) ?? defaultValue) as T;
    if (T == int) return (prefs.getInt(key) ?? defaultValue) as T;
    if (T == bool) return (prefs.getBool(key) ?? defaultValue) as T;
    if (T == double) return (prefs.getDouble(key) ?? defaultValue) as T;
    throw UnsupportedError("类型不支持");

  }

  Future<void> setValue(T newValue) async {
    final prefs = await _prefs;
    if (newValue is String) prefs.setString(key, newValue);
    if (newValue is int) prefs.setInt(key, newValue);
    if (newValue is bool) prefs.setBool(key, newValue);
    if (newValue is double) prefs.setDouble(key, newValue);
  }
}