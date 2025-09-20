// Legacy forwarder to the canonical renderer in ShareService.
import '../models/profile.dart';
import 'share_service.dart';

String exportAsText(Profile p) => ShareService.renderShareText(p);

String smsText(Profile p) => ShareService.renderShareText(p);
