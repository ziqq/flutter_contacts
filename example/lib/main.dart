import 'package:contacts_service_example/src/screens/contacts_list_screen.dart';
import 'package:contacts_service_example/src/screens/navite_contacts_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const ContactsExampleApp());

// iOS only: Localized labels language setting is equal to CFBundleDevelopmentRegion value (Info.plist) of the iOS project
// Set iOSLocalizedLabels=false if you always want english labels whatever is the CFBundleDevelopmentRegion value.
const iOSLocalizedLabels = false;

class ContactsExampleApp extends StatelessWidget {
  const ContactsExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: const HomePage(),
        routes: <String, WidgetBuilder>{
          '/add': (_) => const AddContactPage(),
          '/contacts-list': (_) => const ContactsListScreen(),
          '/native-contacts-picker': (_) => const NativeContactsPickerScreen(),
        },
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _askPermissions();
  }

  Future<void> _askPermissions([String? routeName]) async {
    final navigator = Navigator.of(context);
    final permissionStatus = await _getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      if (routeName != null) await navigator.pushNamed(routeName);
    } else {
      _handleInvalidPermissions(permissionStatus);
    }
  }

  Future<PermissionStatus> _getContactPermission() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      PermissionStatus permissionStatus = await Permission.contacts.request();
      return permissionStatus;
    } else {
      return permission;
    }
  }

  void _handleInvalidPermissions(PermissionStatus permissionStatus) {
    Widget? content;
    if (permissionStatus == PermissionStatus.denied) {
      content = const Text('Access to contact data denied');
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      content = const Text('Contact data not available on device');
    }
    if (content == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: content));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Contacts Plugin Example')),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ElevatedButton(
                child: const Text('Contacts list'),
                onPressed: () => _askPermissions('/contacts-list'),
              ),
              ElevatedButton(
                child: const Text('Native Contacts picker'),
                onPressed: () => _askPermissions('/native-contacts-picker'),
              ),
            ],
          ),
        ),
      );
}
