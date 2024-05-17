import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fasum/screens/home_screen.dart';
import 'package:fasum/screens/sign_up_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

final googleSignIn = GoogleSignIn(
  scopes: [
    'email',
  ],
  clientId:
      '410302709481-dj10c7h49tkmv1s63m9m1h7obuje4tbd.apps.googleusercontent.com',
);

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  Future<void> _signInWIthGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_errorMessage),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32.0),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  final email = _emailController.text.trim();
                  final password = _passwordController.text;
                  // Validasi email
                  if (email.isEmpty || !isValidEmail(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a valid email')),
                    );
                    return;
                  }
                  // Validasi password
                  if (password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter your password')),
                    );
                    return;
                  }
                  try {
                    // Lakukan sign in dengan email dan password
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    // Jika berhasil sign in, navigasi ke halaman beranda
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                    );
                  } on FirebaseAuthException catch (error) {
                    print('Error code: ${error.code}');
                    if (error.code == 'user-not-found') {
                      // Jika email tidak terdaftar, tampilkan pesan kesalahan
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('No user found with that email')),
                      );
                    } else if (error.code == 'wrong-password') {
                      // Jika password salah, tampilkan pesan kesalahan
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Wrong password. Please try again.')),
                      );
                    } else {
                      // Jika terjadi kesalahan lain, tampilkan pesan kesalahan umum
                      setState(() {
                        _errorMessage = error.message ?? 'An error occurred';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_errorMessage),
                        ),
                      );
                    }
                  } catch (error) {
                    // Tangani kesalahan lain yang tidak terkait denganotentikasi
                    setState(() {
                      _errorMessage = error.toString();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_errorMessage),
                      ),
                    );
                  }
                },
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 32.0),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignUpScreen()),
                  );
                },
                child: const Text('Don\'t have an account? Sign up'),
              ),
              const SizedBox(height: 32.0),
              ElevatedButton.icon(
                  onPressed: _signInWIthGoogle,
                  icon: SizedBox(
                    width: 24.0,
                    height: 24.0,
                    child: Image.asset('assets/images/icongoogle.png'),
                  ),
                  label: const Text(
                    'Sign In with Google',
                  )),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi untuk memeriksa validitas email
  bool isValidEmail(String email) {
    String emailRegex =
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$";
    RegExp regex = RegExp(emailRegex);
    return regex.hasMatch(email);
  }
}
