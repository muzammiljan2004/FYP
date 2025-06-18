import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'utils/validation_utils.dart';

class PassengerProfilePage extends StatefulWidget {
  const PassengerProfilePage({Key? key}) : super(key: key);

  @override
  State<PassengerProfilePage> createState() => _PassengerProfilePageState();
}

class _PassengerProfilePageState extends State<PassengerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _streetController = TextEditingController();
  final _cnicController = TextEditingController();
  final _licenseController = TextEditingController();
  String? _selectedCity;
  String? _selectedDistrict;
  bool _isLoading = true;

  final List<String> _cities = ['City 1', 'City 2', 'City 3'];
  final List<String> _districts = ['District 1', 'District 2', 'District 3'];

  File? _profileImage;
  File? _cnicImage;
  File? _licenseImage;
  String? _profileImageUrl;
  String? _cnicImageUrl;
  String? _licenseImageUrl;

  final ImagePicker _picker = ImagePicker();

  Country _selectedCountry = Country(
    phoneCode: '92',
    countryCode: 'PK',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Pakistan',
    example: '0301XXXXXXX',
    displayName: 'Pakistan',
    displayNameNoCountryCode: 'Pakistan',
    e164Key: '',
  );

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _emailController.text = data['email'] ?? '';
            _streetController.text = data['street'] ?? '';
            _selectedCity = data['city'];
            _selectedDistrict = data['district'];
            _profileImageUrl = data['profileImageUrl'];
            _cnicController.text = data['cnic'] ?? '';
            _licenseController.text = data['licenseNumber'] ?? '';
            _cnicImageUrl = data['cnicImageUrl'];
            _licenseImageUrl = data['licenseImageUrl'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_profileImage == null) return _profileImageUrl;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      await ref.putFile(_profileImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<String?> _uploadFile(File? file, String path) async {
    if (file == null) return null;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final ref = FirebaseStorage.instance.ref().child(path).child('${user.uid}.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final profileImageUrl = await _uploadFile(_profileImage, 'profile_images');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'street': _streetController.text.trim(),
        'city': _selectedCity,
        'district': _selectedDistrict,
        'profileImageUrl': profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : null,
                      child: (_profileImage == null && _profileImageUrl == null)
                          ? const Icon(Icons.person, size: 48, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Full Name',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: ValidationUtils.validateName,
              ),
              const SizedBox(height: 16),
              // Phone with country picker
              Row(
                children: [
                  InkWell(
                    onTap: _showCountryPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(_selectedCountry.flagEmoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 4),
                          Text('+${_selectedCountry.phoneCode}', style: const TextStyle(fontSize: 16)),
                          const Icon(Icons.arrow_drop_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Your mobile number',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: ValidationUtils.validatePhone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: ValidationUtils.validateEmail,
              ),
              const SizedBox(height: 16),
              // Street
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  hintText: 'Street Address',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: ValidationUtils.validateAddress,
              ),
              const SizedBox(height: 16),
              // City Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCity,
                hint: const Text('City'),
                items: _cities
                    .map((city) => DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCity = value),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) => ValidationUtils.validateDropdown(value, 'city'),
              ),
              const SizedBox(height: 16),
              // District Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                hint: const Text('District'),
                items: _districts
                    .map((district) => DropdownMenuItem(
                          value: district,
                          child: Text(district),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedDistrict = value),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) => ValidationUtils.validateDropdown(value, 'district'),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2F7D),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _cnicController.dispose();
    _licenseController.dispose();
    super.dispose();
  }
} 