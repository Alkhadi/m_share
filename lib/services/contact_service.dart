import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

/// Lightweight result object returned when adding a contact.  Only includes
/// the name, phone and email for convenience.  Additional fields may be
/// added in the future.
class ContactResult {
  const ContactResult({required this.name, this.phone, this.email});
  final String name;
  final String? phone;
  final String? email;
}

/// Service wrapper around the contacts_service plugin.  Exposes
/// functionality to create contacts on the device in a platform aware
/// manner.  If the contacts_service package is unavailable or
/// unsupported on the current platform, the method will simply return
/// the provided data wrapped in a [ContactResult] without attempting to
/// persist it.
class ContactService {
  const ContactService._();

  /// Saves a new contact directly to the device's contacts list.  The
  /// [name] parameter is required.  Optional fields include [phone],
  /// [email] and [address].  When [business] is true, an organization
  /// identifier is added to the contact to differentiate between
  /// business and personal entries.  Returns a [ContactResult] on
  /// success or `null` if the operation fails or is cancelled.
  static Future<ContactResult?> saveContact({
    required String name,
    String? phone,
    String? email,
    String? address,
    bool business = false,
  }) async {
    try {
      // On web or unsupported platforms we cannot save contacts.  In that
      // case simply return the provided information.
      if (kIsWeb) {
        return ContactResult(name: name, phone: phone, email: email);
      }

      // Request permission via flutter_contacts.  It encapsulates
      // platform‑specific permission dialogs on both Android and iOS.
      final bool permissionGranted = await FlutterContacts.requestPermission();
      if (!permissionGranted) {
        return ContactResult(name: name, phone: phone, email: email);
      }

      // Construct the contact using flutter_contacts models.
      final contact = Contact();
      // Set the display name and structured name.  The displayName is
      // automatically derived from the structured name.
      contact.name = Name(first: name);
      if (phone != null && phone.isNotEmpty) {
        contact.phones = [Phone(phone)];
      }
      if (email != null && email.isNotEmpty) {
        contact.emails = [Email(email)];
      }
      if (address != null && address.isNotEmpty) {
        contact.addresses = [Address(address)];
      }
      if (business) {
        // When marked as business, set an organization label to help
        // differentiate in native contacts apps.  We leave the company
        // name blank because the user may choose to fill it later.
        contact.organizations = [Organization(company: '', title: 'Business')];
      }
      // Insert the contact into the system.  This may throw on
      // unsupported platforms.
      await contact.insert();
      return ContactResult(name: name, phone: phone, email: email);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Contact save failed: $e');
      }
      return null;
    }
  }
}