import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'change_password_page.dart';
import 'change_language_page.dart';
import 'privacy_policy_page.dart';
import 'contact_us_page.dart';
import 'delete_account_page.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        children: [
          ListTile(
            title: Text('change_password'.tr()),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordPage())),
          ),
          ListTile(
            title: Text('change_language'.tr()),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeLanguagePage())),
          ),
          ListTile(
            title: Text('privacy_policy'.tr()),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyPolicyPage())),
          ),
          ListTile(
            title: Text('contact_us'.tr()),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactUsPage())),
          ),
          ListTile(
            title: Text('delete_account'.tr()),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeleteAccountPage())),
          ),
        ],
      ),
    );
  }
} 