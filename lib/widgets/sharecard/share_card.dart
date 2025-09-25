import 'dart:typed_data';
import '../../models/profile_data.dart';

/// Stub implementation for generating a share card image.  In this
/// simplified example the function returns an empty byte array.  A
/// real implementation would render a widget to an image using
/// `ui.PictureRecorder` and `Canvas`.
Future<Uint8List> buildShareCardImageBytes(ProfileData data, Uri profileUrl) async {
  // TODO: generate an actual PNG representation of the profile.
  return Uint8List(0);
}