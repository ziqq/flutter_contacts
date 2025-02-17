import 'dart:developer';

import 'package:contacts_service/contacts_service.dart';
import 'package:contacts_service_example/main.dart';
import 'package:flutter/material.dart';

class NativeContactsPickerScreen extends StatefulWidget {
  const NativeContactsPickerScreen({super.key});

  @override
  State<NativeContactsPickerScreen> createState() =>
      _NativeContactsPickerScreenState();
}

class _NativeContactsPickerScreenState
    extends State<NativeContactsPickerScreen> {
  Contact? _contact;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickContact() async {
    try {
      final Contact? contact = await ContactsService.openDeviceContactPicker(
        iOSLocalizedLabels: iOSLocalizedLabels,
      );
      setState(() => _contact = contact);
    } on Object catch (e) {
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Contacts Picker Example')),
        body: SafeArea(
            child: Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickContact,
              child: const Text('Pick a contact'),
            ),
            if (_contact != null)
              Text('Contact selected: ${_contact?.displayName}'),
          ],
        )),
      );
}
