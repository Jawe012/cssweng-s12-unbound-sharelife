import 'package:flutter/material.dart';
import 'package:the_basics/auth/auth_service.dart';
import 'package:the_basics/core/widgets/auth_navbar.dart';
import 'package:the_basics/core/utils/remember_me.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // get auth service
  final authService = AuthService();

  // text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    // load remembered email if any
    RememberMe.getEmail().then((email) {
      if (email != null && email.isNotEmpty) {
        _emailController.text = email;
        setState(() => _rememberMe = true);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // login button pressed
  void login() async {
    final credential = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // If empty input, do nothing
    if (credential.isEmpty || password.isEmpty) {
      return;
    }

    try {
      await authService.signInWithEmailPassword(credential, password);
      // On success, persist or clear remembered email as chosen
      if (_rememberMe) {
        await RememberMe.saveEmail(credential);
      } else {
        await RememberMe.clear();
      }
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      
      // Check if it's a username login attempt that failed
      final isUsername = !credential.contains('@');
      
      if (isUsername) {
        // Username login failed - could be wrong credentials, non-existent user, or need email for first login
        if (errorMsg.contains('invalid') || errorMsg.contains('credentials') || errorMsg.contains('password')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid credentials. Please check your username and password.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed. Please use your email for first-time login, or check if the username exists.')),
          );
        }
      } else {
        // Email login failed
        if (errorMsg.contains('invalid') || errorMsg.contains('credentials') || errorMsg.contains('password')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid credentials. Please check your email and password.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [
          const AuthNavBar(),
          Expanded(
            child: Center(
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Username or Email Address
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                          labelText: 'Username or Email Address',
                          border: OutlineInputBorder(),
                          hintText: 'Username or Email Address'),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          hintText: 'Password'),
                    ),
                    const SizedBox(height: 8),

                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/reset-password');
                        }, 
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Remember me checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) => setState(() => _rememberMe = value ?? false),
                        ),
                        const Text('Remember me?'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Log in button
                    ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C0C0D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
