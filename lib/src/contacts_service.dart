// ignore_for_file: sort_constructors_first

import 'dart:async';

import 'package:contacts_service/src/exception.dart';
import 'package:contacts_service/src/model.dart';
import 'package:contacts_service/src/typedef.dart';
import 'package:flutter/services.dart';

export 'share.dart';

/// {@template contacts_service}
/// A service that provides access to the device contacts.
/// {@endtemplate}
final class ContactsService {
  /// {@macro contacts_service}
  const ContactsService._();

  // static final ContactsService instance = ContactsService._internal();
  // factory ContactsService() => instance;

  /// {@macro contacts_service}
  // ContactsService._internal();

  /// The [MethodChannel] used to interact with the platform side of the plugin.
  static const MethodChannel _channel =
      MethodChannel('github.com/clovisnicolas/flutter_contacts');

  /// Fetches all contacts, or when specified, the contacts with a name
  /// matching [query]
  static Future<List<Contact>> getContacts({
    String? query,
    bool withThumbnails = true,
    bool photoHighResolution = true,
    bool orderByGivenName = true,
    bool iOSLocalizedLabels = true,
    bool androidLocalizedLabels = true,
  }) async {
    final contacts = await _channel.invokeMethod(
      'getContacts',
      <String, dynamic>{
        'query': query,
        'withThumbnails': withThumbnails,
        'photoHighResolution': photoHighResolution,
        'orderByGivenName': orderByGivenName,
        'iOSLocalizedLabels': iOSLocalizedLabels,
        'androidLocalizedLabels': androidLocalizedLabels,
      },
    );
    return (contacts as Iterable<dynamic>)
        .map((c) => Contact.fromMap(c as JSON))
        .toList();
  }

  /// Fetches all contacts, or when specified, the contacts with the phone
  /// matching [phone]
  static Future<List<Contact>> getContactsForPhone(
    String? phone, {
    bool withThumbnails = true,
    bool photoHighResolution = true,
    bool orderByGivenName = true,
    bool iOSLocalizedLabels = true,
    bool androidLocalizedLabels = true,
  }) async {
    if (phone == null || phone.isEmpty) return List.empty();

    final contacts =
        await _channel.invokeMethod('getContactsForPhone', <String, dynamic>{
      'phone': phone,
      'withThumbnails': withThumbnails,
      'photoHighResolution': photoHighResolution,
      'orderByGivenName': orderByGivenName,
      'iOSLocalizedLabels': iOSLocalizedLabels,
      'androidLocalizedLabels': androidLocalizedLabels,
    });
    return (contacts as Iterable<dynamic>)
        .map((c) => Contact.fromMap(c as JSON))
        .toList();
  }

  /// Fetches all contacts, or when specified, the contacts with the email
  /// matching [email]
  /// Works only on iOS
  static Future<List<Contact>> getContactsForEmail(String email,
      {bool withThumbnails = true,
      bool photoHighResolution = true,
      bool orderByGivenName = true,
      bool iOSLocalizedLabels = true,
      bool androidLocalizedLabels = true}) async {
    final contacts = await _channel.invokeMethod(
      'getContactsForEmail',
      <String, dynamic>{
        'email': email,
        'withThumbnails': withThumbnails,
        'photoHighResolution': photoHighResolution,
        'orderByGivenName': orderByGivenName,
        'iOSLocalizedLabels': iOSLocalizedLabels,
        'androidLocalizedLabels': androidLocalizedLabels,
      },
    );
    if (contacts is! List) return const [];
    return contacts.map((c) => Contact.fromMap(c as JSON)).toList();
  }

  /// Loads the avatar for the given contact and returns it. If the user does
  /// not have an avatar, then `null` is returned in that slot. Only implemented
  /// on Android.
  static Future<Uint8List?> getAvatar(
    final Contact contact, {
    final bool photoHighRes = true,
  }) =>
      _channel.invokeMethod(
        'getAvatar',
        <String, dynamic>{
          'contact': contact.toMap(),
          'identifier': contact.identifier,
          'photoHighResolution': photoHighRes,
        },
      );

  /// Adds the [contact] to the device contact list
  static Future<void> addContact(Contact contact) =>
      _channel.invokeMethod('addContact', contact.toMap());

  /// Deletes the [contact] if it has a valid identifier
  static Future<void> deleteContact(Contact contact) =>
      _channel.invokeMethod('deleteContact', contact.toMap());

  /// Updates the [contact] if it has a valid identifier
  static Future<void> updateContact(Contact contact) =>
      _channel.invokeMethod('updateContact', contact.toMap());

  /// Opens the contact form with the fields prefilled with the values from the
  static Future<Contact> openContactForm({
    bool iOSLocalizedLabels = true,
    bool androidLocalizedLabels = true,
  }) async {
    final result = await _channel.invokeMethod(
      'openContactForm',
      <String, dynamic>{
        'iOSLocalizedLabels': iOSLocalizedLabels,
        'androidLocalizedLabels': androidLocalizedLabels,
      },
    );
    return _handleFormOperation(result);
  }

  /// Opens the contact form with the fields prefilled with the values from the
  /// [contact] parameter
  static Future<Contact> openExistingContact(
    Contact contact, {
    bool iOSLocalizedLabels = true,
    bool androidLocalizedLabels = true,
  }) async {
    dynamic result = await _channel.invokeMethod(
      'openExistingContact',
      <String, dynamic>{
        'contact': contact.toMap(),
        'iOSLocalizedLabels': iOSLocalizedLabels,
        'androidLocalizedLabels': androidLocalizedLabels,
      },
    );
    return _handleFormOperation(result);
  }

  // Displays the device/native contact picker dialog and returns the contact selected by the user
  static Future<Contact?> openDeviceContactPicker({
    bool iOSLocalizedLabels = true,
    bool androidLocalizedLabels = true,
  }) async {
    var result = await _channel.invokeMethod(
      'openDeviceContactPicker',
      <String, dynamic>{
        'iOSLocalizedLabels': iOSLocalizedLabels,
        'androidLocalizedLabels': androidLocalizedLabels,
      },
    );
    // result contains either :
    // - an List of contacts containing 0 or 1 contact
    // - a FormOperationErrorCode value
    if (result is List) {
      if (result.isEmpty) return null;
      result = result.first;
    }
    return _handleFormOperation(result);
  }

  // ignore: avoid_annotating_with_dynamic
  static Contact _handleFormOperation(dynamic result) {
    if (result is int) {
      switch (result) {
        case 1:
          throw const FormOperationException(
            errorCode: FormOperationErrorCode.FORM_OPERATION_CANCELED,
          );
        case 2:
          throw const FormOperationException(
            errorCode: FormOperationErrorCode.FORM_COULD_NOT_BE_OPEN,
          );
        default:
          throw const FormOperationException(
            errorCode: FormOperationErrorCode.FORM_OPERATION_UNKNOWN_ERROR,
          );
      }
    } else if (result is JSON) {
      return Contact.fromMap(result);
    } else {
      throw const FormOperationException(
        errorCode: FormOperationErrorCode.FORM_OPERATION_UNKNOWN_ERROR,
      );
    }
  }
}
