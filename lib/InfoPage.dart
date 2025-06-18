import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'verify.dart';
import 'login.dart';
import 'utils/validation_utils.dart';

class InfoPage extends StatefulWidget {
  final String role;
  const InfoPage({Key? key, required this.role}) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  String? _selectedGender;
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

  bool _isValidEmail(String v) {
    return RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
        .hasMatch(v);
  }

  void _onSignupPressed(BuildContext context, String phoneNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyPage(
          phoneNumber: phoneNumber,
          verificationId: 'dummy-id', // This is not used anymore
          role: widget.role,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          gender: _selectedGender ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sign up with your email or phone number",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: ValidationUtils.validateName,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: ValidationUtils.validateEmail,
              ),
              const SizedBox(height: 16),

              // Mobile Number
              Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: true,
                          onSelect: (Country country) {
                            setState(() {
                              _selectedCountry = country;
                            });
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Text(_selectedCountry.flagEmoji,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 48,
                      width: 1,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    Text('+${_selectedCountry.phoneCode}',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: "Your mobile number",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(right: 12),
                        ),
                        validator: ValidationUtils.validatePhone,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Gender dropdown
              DropdownButtonFormField<String>(
                value: _selectedGender,
                hint: const Text("Gender"),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedGender = v),
                validator: (v) => ValidationUtils.validateDropdown(v, 'gender'),
              ),
              const SizedBox(height: 16),

              // Terms & Privacy
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      children: const [
                        Text("By signing up, you agree to the "),
                        Text("Terms of service",
                            style: TextStyle(color: Colors.blue)),
                        Text(" and "),
                        Text("Privacy policy",
                            style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final mobileNumber =
                          '+${_selectedCountry.phoneCode}${_mobileController.text.trim()}';
                      _onSignupPressed(context, mobileNumber);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2F7D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Sign Up",
                      style: TextStyle(color: Colors.white)),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("or"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => print("Google sign up"),
                  icon: Image.asset("assets/google_logo.png", height: 20),
                  label: const Text("Sign up with Gmail"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: const Text("Sign in",
                        style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
