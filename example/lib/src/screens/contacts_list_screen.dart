import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:contacts_service_example/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListPageState();
}

class _ContactsListPageState extends State<ContactsListScreen> {
  List<Contact>? _contacts;

  @override
  void initState() {
    super.initState();
    refreshContacts();
  }

  Future<void> refreshContacts() async {
    // var contacts = (await ContactsService.getContactsForPhone("8554964652"));

    // Load without thumbnails initially.
    final contacts = await ContactsService.getContacts(
      iOSLocalizedLabels: iOSLocalizedLabels,
      withThumbnails: false,
    );

    setState(() => _contacts = contacts);

    // Lazy load thumbnails after rendering initial contacts.
    for (var contact in _contacts ?? contacts) {
      await ContactsService.getAvatar(contact).then((avatar) {
        setState(() => contact = contact.copyWith(avatar: avatar));
      });
    }
  }

  Future<void> updateContact() async {
    Contact? ninja = _contacts
        ?.firstWhereOrNull((c) => c.familyName?.startsWith('Ninja') ?? false);
    if (ninja == null) return;
    await ContactsService.updateContact(ninja);
    await refreshContacts();
  }

  Future<void> _openContactForm() async {
    try {
      var _ = await ContactsService.openContactForm(
        iOSLocalizedLabels: iOSLocalizedLabels,
      );
      await refreshContacts();
    } on FormOperationException catch (e) {
      switch (e.errorCode) {
        case FormOperationErrorCode.FORM_OPERATION_CANCELED:
        case FormOperationErrorCode.FORM_COULD_NOT_BE_OPEN:
        case FormOperationErrorCode.FORM_OPERATION_UNKNOWN_ERROR:
        default:
          log(e.errorCode.toString());
      }
    }
  }

  void contactOnDeviceHasBeenUpdated(Contact contact) {
    var id = _contacts?.indexWhere((c) => c.identifier == contact.identifier);
    if (id == null || id < 0) return;
    _contacts?[id] = contact;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Contacts Plugin Example'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.create),
              onPressed: _openContactForm,
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.of(context).pushNamed('/add').then((_) {
              refreshContacts();
            });
          },
        ),
        body: SafeArea(
          child: _contacts != null
              ? ListView.builder(
                  itemCount: _contacts?.length ?? 0,
                  itemBuilder: (context, index) {
                    Contact? c = _contacts?.elementAt(index);
                    if (c == null) return const SizedBox.shrink();
                    return ListTile(
                      onTap: () {
                        final route = MaterialPageRoute<void>(
                          builder: (context) => ContactDetailsPage(
                            c,
                            onContactDeviceSave: contactOnDeviceHasBeenUpdated,
                          ),
                        );
                        Navigator.of(context).push(route);
                      },
                      leading: (c.avatar != null && (c.avatar?.length ?? 0) > 0)
                          ? CircleAvatar(
                              backgroundImage: MemoryImage(c.avatar!))
                          : CircleAvatar(child: Text(c.initials())),
                      title: Text(c.displayName ?? ''),
                    );
                  },
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      );
}

class ContactDetailsPage extends StatelessWidget {
  const ContactDetailsPage(
    this._contact, {
    this.onContactDeviceSave,
    super.key,
  });

  final Contact _contact;
  final void Function(Contact)? onContactDeviceSave;

  Future<void> _openExistingContactOnDevice(BuildContext context) async {
    try {
      var contact = await ContactsService.openExistingContact(
        _contact,
        iOSLocalizedLabels: iOSLocalizedLabels,
      );
      if (onContactDeviceSave != null) {
        onContactDeviceSave?.call(contact);
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } on FormOperationException catch (e) {
      switch (e.errorCode) {
        case FormOperationErrorCode.FORM_OPERATION_CANCELED:
        case FormOperationErrorCode.FORM_COULD_NOT_BE_OPEN:
        case FormOperationErrorCode.FORM_OPERATION_UNKNOWN_ERROR:
        default:
          log(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_contact.displayName ?? ''),
          actions: <Widget>[
//          IconButton(
//            icon: Icon(Icons.share),
//            onPressed: () => shareVCFCard(context, contact: _contact),
//          ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => ContactsService.deleteContact(_contact),
            ),
            IconButton(
              icon: const Icon(Icons.update),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => UpdateContactsPage(
                    contact: _contact,
                  ),
                ),
              ),
            ),
            IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _openExistingContactOnDevice(context)),
          ],
        ),
        body: SafeArea(
          child: ListView(
            children: <Widget>[
              ListTile(
                title: const Text('Name'),
                trailing: Text(_contact.givenName ?? ''),
              ),
              ListTile(
                title: const Text('Middle name'),
                trailing: Text(_contact.middleName ?? ''),
              ),
              ListTile(
                title: const Text('Family name'),
                trailing: Text(_contact.familyName ?? ''),
              ),
              ListTile(
                title: const Text('Prefix'),
                trailing: Text(_contact.prefix ?? ''),
              ),
              ListTile(
                title: const Text('Suffix'),
                trailing: Text(_contact.suffix ?? ''),
              ),
              ListTile(
                title: const Text('Birthday'),
                trailing: Text(_contact.birthday != null
                    ? DateFormat('dd-MM-yyyy').format(_contact.birthday!)
                    : ''),
              ),
              ListTile(
                title: const Text('Company'),
                trailing: Text(_contact.company ?? ''),
              ),
              ListTile(
                title: const Text('Job'),
                trailing: Text(_contact.jobTitle ?? ''),
              ),
              ListTile(
                title: const Text('Account Type'),
                trailing: Text((_contact.androidAccountType != null)
                    ? _contact.androidAccountType.toString()
                    : ''),
              ),
              AddressesTile(_contact.postalAddresses!),
              ItemsTile('Phones', _contact.phones!),
              ItemsTile('Emails', _contact.emails!)
            ],
          ),
        ),
      );
}

@immutable
class AddressesTile extends StatelessWidget {
  const AddressesTile(this._addresses, {super.key});

  final List<PostalAddress> _addresses;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const ListTile(title: Text('Addresses')),
          Column(
            children: [
              for (final a in _addresses)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        title: const Text('Street'),
                        trailing: Text(a.street ?? ''),
                      ),
                      ListTile(
                        title: const Text('Postcode'),
                        trailing: Text(a.postcode ?? ''),
                      ),
                      ListTile(
                        title: const Text('City'),
                        trailing: Text(a.city ?? ''),
                      ),
                      ListTile(
                        title: const Text('Region'),
                        trailing: Text(a.region ?? ''),
                      ),
                      ListTile(
                        title: const Text('Country'),
                        trailing: Text(a.country ?? ''),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      );
}

class ItemsTile extends StatelessWidget {
  const ItemsTile(this._title, this._items, {super.key});

  final List<Item> _items;
  final String _title;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(title: Text(_title)),
          Column(
            children: [
              for (final i in _items)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    title: Text(i.label ?? ''),
                    trailing: Text(i.value ?? ''),
                  ),
                ),
            ],
          ),
        ],
      );
}

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<StatefulWidget> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  PostalAddress address = const PostalAddress(label: 'Home');
  Contact contact = const Contact();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Add a contact'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _formKey.currentState?.save();
                final newContact = contact.copyWith(postalAddresses: [address]);
                ContactsService.addContact(newContact);
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.save, color: Colors.white),
            )
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'First name'),
                  onSaved: (v) => contact.copyWith(givenName: v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Middle name'),
                  onSaved: (v) => contact.copyWith(middleName: v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Last name'),
                  onSaved: (v) => contact = contact.copyWith(familyName: v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Prefix'),
                  onSaved: (v) => contact = contact.copyWith(prefix: v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Suffix'),
                  onSaved: (v) => contact = contact.copyWith(suffix: v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Phone'),
                  onSaved: (v) => contact = contact
                      .copyWith(phones: [Item(label: 'mobile', value: v)]),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  onSaved: (v) => contact = contact.copyWith(
                    emails: [Item(label: 'work', value: v)],
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Company'),
                  onSaved: (v) => contact = contact.copyWith(company: v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Job'),
                  onSaved: (v) => contact = contact.copyWith(jobTitle: v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Street'),
                  onSaved: (v) => address = address.copyWith(street: v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'City'),
                  onSaved: (v) => address = address.copyWith(city: v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Region'),
                  onSaved: (v) => address = address.copyWith(region: v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Postal code'),
                  onSaved: (v) => address = address.copyWith(postcode: v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Country'),
                  onSaved: (v) => address = address.copyWith(country: v),
                ),
              ],
            ),
          ),
        ),
      );
}

@immutable
class UpdateContactsPage extends StatefulWidget {
  const UpdateContactsPage({@required this.contact, super.key});

  final Contact? contact;

  @override
  State<UpdateContactsPage> createState() => _UpdateContactsPageState();
}

class _UpdateContactsPageState extends State<UpdateContactsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  PostalAddress address = const PostalAddress(label: 'Home');
  Contact? contact;

  @override
  void initState() {
    super.initState();
    contact = widget.contact;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Update Contact'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.save,
                color: Colors.white,
              ),
              onPressed: () async {
                _formKey.currentState?.save();
                final navigator = Navigator.of(context);
                final newContact =
                    contact?.copyWith(postalAddresses: [address]);
                if (newContact == null) return;
                await ContactsService.updateContact(newContact);
                await navigator.pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => const ContactsListScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                TextFormField(
                  initialValue: contact?.givenName ?? '',
                  decoration: const InputDecoration(labelText: 'First name'),
                  onSaved: (v) => contact = contact?.copyWith(givenName: v),
                ),
                TextFormField(
                  initialValue: contact?.middleName ?? '',
                  decoration: const InputDecoration(labelText: 'Middle name'),
                  onSaved: (v) => contact = contact?.copyWith(middleName: v),
                ),
                TextFormField(
                  initialValue: contact?.familyName ?? '',
                  decoration: const InputDecoration(labelText: 'Last name'),
                  onSaved: (v) => contact = contact?.copyWith(familyName: v),
                ),
                TextFormField(
                  initialValue: contact?.prefix ?? '',
                  decoration: const InputDecoration(labelText: 'Prefix'),
                  onSaved: (v) => contact = contact?.copyWith(prefix: v),
                ),
                TextFormField(
                  initialValue: contact?.suffix ?? '',
                  decoration: const InputDecoration(labelText: 'Suffix'),
                  onSaved: (v) => contact = contact?.copyWith(suffix: v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Phone'),
                  onSaved: (v) => contact = contact
                      ?.copyWith(phones: [Item(label: 'mobile', value: v)]),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  onSaved: (v) => contact = contact?.copyWith(
                    emails: [Item(label: 'work', value: v)],
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextFormField(
                  initialValue: contact?.company ?? '',
                  decoration: const InputDecoration(labelText: 'Company'),
                  onSaved: (v) => contact = contact?.copyWith(company: v),
                ),
                TextFormField(
                  initialValue: contact?.jobTitle ?? '',
                  decoration: const InputDecoration(labelText: 'Job'),
                  onSaved: (v) => contact = contact?.copyWith(jobTitle: v),
                ),
                TextFormField(
                  initialValue: address.street ?? '',
                  decoration: const InputDecoration(labelText: 'Street'),
                  onSaved: (v) => address = address.copyWith(street: v),
                ),
                TextFormField(
                  initialValue: address.city ?? '',
                  decoration: const InputDecoration(labelText: 'City'),
                  onSaved: (v) => address = address.copyWith(city: v),
                ),
                TextFormField(
                  initialValue: address.region ?? '',
                  decoration: const InputDecoration(labelText: 'Region'),
                  onSaved: (v) => address = address.copyWith(region: v),
                ),
                TextFormField(
                  initialValue: address.postcode ?? '',
                  decoration: const InputDecoration(labelText: 'Postal code'),
                  onSaved: (v) => address = address.copyWith(postcode: v),
                ),
                TextFormField(
                  initialValue: address.country ?? '',
                  decoration: const InputDecoration(labelText: 'Country'),
                  onSaved: (v) => address = address.copyWith(country: v),
                ),
              ],
            ),
          ),
        ),
      );
}
