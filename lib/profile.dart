import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'wallet.dart';
import 'home_screen_passenger.dart';
import 'login.dart';
import 'utils/validation_utils.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProfilePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _avatar;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _avatar = File(picked.path);
      });
      Navigator.of(context).pop(); // close drawer if open
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: _avatar != null
                            ? FileImage(_avatar!)
                            : const AssetImage('assets/profile_avatar.png') as ImageProvider,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Nate Samson', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: 4),
                        Text('nate@email.com', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('History'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.report_problem_outlined),
                title: const Text('Complain'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.card_giftcard),
                title: const Text('Referral'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileReferralPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Us'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help and Support'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // top menu + title row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Profile',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(width: 48), // for layout balance
                  ],
                ),
              ),
              SizedBox(height: 8),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: _avatar != null
                        ? FileImage(_avatar!)
                        : const AssetImage('assets/profile_avatar.png') as ImageProvider,
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 16),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Nate Samson',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildTextField(hint: 'nate@email.com', horizontal: 20),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 55,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text("🇧🇩")),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          prefixText: '+880 ',
                          hintText: 'Your mobile number',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: ValidationUtils.validatePhone,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  value: 'Male',
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(child: Text(g), value: g))
                      .toList(),
                  onChanged: (_) {},
                ),
              ),
              SizedBox(height: 10),
              _buildTextField(hint: 'Address', horizontal: 20),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Logout', style: TextStyle(color: Colors.blue)),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WalletPage()),
            );
          } else if (index == 2) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
              (route) => false,
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required String hint, required double horizontal}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      child: TextFormField(
        decoration: InputDecoration(
          hintText: hint,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) {
          if (hint.toLowerCase().contains('email')) {
            return ValidationUtils.validateEmail(value);
          } else if (hint.toLowerCase().contains('address')) {
            return ValidationUtils.validateAddress(value);
          }
          return ValidationUtils.validateRequired(value, hint);
        },
      ),
    );
  }
}
class ProfileReferralPage extends StatelessWidget {
  const ProfileReferralPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Referral')),
      body: const Center(child: Text('Referral Page Content')),
    );
  }
}
