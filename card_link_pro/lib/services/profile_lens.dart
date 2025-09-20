import '../models/profile.dart';

class ProfileLens {
  static String? website(Profile p) =>
      (p.website.isNotEmpty) ? p.website : null;
}
