import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'login.dart';
import 'signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

const Color primaryButtonColor = Color(0xFF2D2F7D);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCptuN6Tz-K-OHxkuffQNtYzsPBu7u6VVY",
        authDomain: "wego-app-c0a8d.firebaseapp.com",
        projectId: "wego-app-c0a8d",
        storageBucket: "wego-app-c0a8d.appspot.com",
        messagingSenderId: "279686141911",
        appId: "1:279686141911:web:a25a84d877720b34385d92",
        measurementId: "G-ZG7LS19R52",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('en'),
        Locale('fr'),
        Locale('es'),
        Locale('de'),
        Locale('tr'),
        Locale('pt'),
        Locale('nl'),
        Locale('ar'),
        Locale('hi'),
      ],
      path: 'assets/langs',
      fallbackLocale: Locale('en'),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Welcome Screen',
      home: WelcomeScreen(),
      routes: {
        '/termsAndConditions': (context) => TermsAndConditionsScreen(),
        '/signup': (context) => const SignupScreen(),
      },
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Color.fromARGB(255, 247, 247, 248), width: 2),
                ),
                child: Image.asset(
                  'assets/welcome_image.png',
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Have a better sharing experience',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black45,
                ),
              ),
              SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/termsAndConditions');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 44, 49, 107),

                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Create an account',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 255, 255, 255),             
                     ),
                    
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text(
                    'Log In',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 44, 49, 107),
                    ),
                  ),
                ),
              ),
            
            ],
          ),
        ),
      ),
    );
  }
}

class TermsAndConditionsScreen extends StatefulWidget {
  @override
  _TermsAndConditionsScreenState createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
        'Terms and Conditions',
        style: TextStyle(
          backgroundColor:Color.fromARGB(255, 44, 49, 107) ,
         color: Color.fromARGB(255, 255, 255, 255)),
          ),
      ),
    
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to our platform! Please read tadhese Terms and Conditions carefully before proceeding. By creating an account or using our services, you agree to be bound by these terms.',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '1. Account Registration:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '- You must be at least 18 years of age to create an account.\n'
                      '- You are responsible for maintaining the confidentiality of your account credentials.\n'
                      '- You agree to provide accurate and complete information during the registration process.',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '2. Use of Services:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '- Our platform provides [briefly describe the core service of your app].\n'
                      '- You agree to use our services only for lawful purposes and in a manner that does not infringe upon the rights of others.\n'
                      '- You are prohibited from engaging in any activity that could disrupt or interfere with the functionality of our platform.',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '3. Privacy:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '- Your privacy is important to us. Please refer to our Privacy Policy for details on how we collect, use, and protect your personal information.',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '4. Intellectual Property:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '- All content and materials available on our platform, including but not limited to text, graphics, logos, and software, are the property of our company and are protected by applicable intellectual property laws.',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '5. Termination:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '- We reserve the right to suspend or terminate your account at any time for violation of these Terms and Conditions.',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '6. Disclaimer of Warranties:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '- Our platform is provided on an "as is" and "as available" basis without any warranties, express or implied.',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '7. Limitation of Liability:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '- To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages.',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '8. Governing Law:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '- These Terms and Conditions shall be governed by and construed in accordance with the laws of your jurisdiction.',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'By clicking "Continue" below, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _agreed,
                  onChanged: (bool? value) {
                    setState(() {
                      _agreed = value ?? false;
                    });
                  },
                ),
                Expanded(child: Text('I agree with terms and conditions')),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _agreed
                    ? () {
                        Navigator.pushNamed(context, '/signup');
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 44, 49, 107),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(fontSize: 16,
                  color: Color.fromARGB(255, 249, 249, 249),
                  ),
                
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
