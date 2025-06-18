import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('privacy_policy'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed euismod mauris nec nibh tempor euismod. Nulla facilisi. Pellentesque egestas magna sed feugiat pretium. Quisque id tortor convallis, dictum sapien vitae, volutpat erat. Etiam nec velit eget orci dictum posuere non non ipsum. Pellentesque euismod euismod facilisis eu facilisis euismod.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ),
    );
  }
} 