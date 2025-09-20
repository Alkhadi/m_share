import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';

class ProfileStore {
  static const _key = 'profile_json';

  static Future<Profile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final j = prefs.getString(_key);
    if (j != null) return Profile.fromJson(j);
    return Profile.defaultProfile();
  }

  static Future<void> save(Profile p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, p.toJson());
  }

  static Profile fromJsonString(String s) => Profile.fromJson(s);
}
