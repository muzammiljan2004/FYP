import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ChangeLanguagePage extends StatelessWidget {
  final List<Map<String, dynamic>> languages = [
    {'locale': Locale('en'), 'name': 'English', 'flag': '🇺🇸'},
    {'locale': Locale('hi'), 'name': 'Hindi', 'flag': '🇮🇳'},
    {'locale': Locale('ar'), 'name': 'Arabic', 'flag': '🇸🇦'},
    {'locale': Locale('fr'), 'name': 'French', 'flag': '🇫🇷'},
    {'locale': Locale('de'), 'name': 'German', 'flag': '🇩🇪'},
    {'locale': Locale('pt'), 'name': 'Portuguese', 'flag': '🇵🇹'},
    {'locale': Locale('tr'), 'name': 'Turkish', 'flag': '🇹🇷'},
    {'locale': Locale('nl'), 'name': 'Dutch', 'flag': '🇳🇱'},
    {'locale': Locale('es'), 'name': 'Spanish', 'flag': '🇪🇸'},
  ];

  @override
  Widget build(BuildContext context) {
    Locale currentLocale = context.locale;
    return Scaffold(
      appBar: AppBar(title: Text('change_language'.tr())),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          return ListTile(
            leading: Text(lang['flag'], style: TextStyle(fontSize: 24)),
            title: Text(lang['name']),
            trailing: currentLocale == lang['locale']
                ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                : null,
            onTap: () async {
              await context.setLocale(lang['locale']);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
} 