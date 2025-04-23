import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Dashboard.dart';

void main() {
  runApp(const MyApp());
}

final SupabaseClient supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Login(),
    );
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String? _userID;
  final TextEditingController emailController =
      TextEditingController(text: "aly@addu.edu.com");
  final TextEditingController passwordController =
      TextEditingController(text: "password123");

  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _userID = data.session?.user?.id;
      });
    });
  }

  Future<void> _nativeGoogleSignIn() async {
    const webClientId =
        '451923571225-16d5gkkhbib2bvov02p7fgv40mi2jiff.apps.googleusercontent.com';
    final GoogleSignIn googleSignIn =
        GoogleSignIn(serverClientId: webClientId);

    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;

    final accessToken = googleAuth?.accessToken;
    final idToken = googleAuth?.idToken;

    if (accessToken != null && idToken != null) {
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      _goToDashboard();
    }
  }

  Future<void> _webGoogleSignIn() async {
    await supabase.auth.signInWithOAuth(OAuthProvider.google, redirectTo: '/');
  }

  void _goToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Dashboard()),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (supabase.auth.currentUser != null) {
        _goToDashboard();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/login.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Card(
            elevation: 20,
            color: Colors.white,
            margin: const EdgeInsets.all(100),
            child: Padding(
              padding: const EdgeInsets.only(left: 60, top: 60),
              child: Row( 
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Uni-Vents",
                          style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 20)),
                      const SizedBox(height: 5),
                      const Text("Ateneo de Davao Events",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 25)),
                      const SizedBox(height: 5),
                      const Text("Welcome Back, Please login to your account",
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 10),
                      _inputBox("Email Address", emailController),
                      _inputBox("Password", passwordController,
                          obscureText: true),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: false,
                            onChanged: (bool? newValue) {},
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            side: const BorderSide(
                                color: Color.fromARGB(255, 215, 214, 214),
                                width: 1),
                          ),
                          const Text("Remember me",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 15)),
                          const SizedBox(width: 145),
                          const Text("Forgot Password?",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 50),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Add login logic here
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              minimumSize: const Size(150, 60),
                            ),
                            child: const Text("Login",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () {
                              // Add signup logic here
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                                side: const BorderSide(color: Colors.blue),
                              ),
                              minimumSize: const Size(150, 60),
                            ),
                            child: const Text("Sign Up",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      _googleButton(),
                    ],
                  ),
                  const SizedBox(width: 50),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/login.jpg'),
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBox(String label, TextEditingController controller,
      {bool obscureText = false}) {
    return Container(
      height: 60,
      width: 400,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(
            width: 1.5, color: const Color.fromARGB(255, 194, 192, 192)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _googleButton() {
    return InkWell(
      onTap: () async {
        if (!kIsWeb && Platform.isAndroid) {
          await _nativeGoogleSignIn();
        } else {
          await _webGoogleSignIn();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/google_logo.png', height: 24),
            const SizedBox(width: 10),
            const Text(
              'Sign in with Google',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
