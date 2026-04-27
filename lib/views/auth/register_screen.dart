import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_wrapper.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _token = TextEditingController();
  String _role = 'Field Lead';
  bool _isLoading = false;

  void _register() async {
    if (_role == 'Field Lead' && _token.text.trim() != 'RELIEF2026') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid access token. Use the token provided by the Chief Director.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final success = await context.read<AuthProvider>().signUp(
        _email.text.trim(), 
        _password.text.trim(),
        _role,
        _name.text.trim(),
        _phone.text.trim(),
      );
      
      if (success && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeWrapper()));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed.')));
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (e is FirebaseAuthException) {
          errorMessage = e.message ?? 'An unknown error occurred.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
               const Icon(Icons.volunteer_activism, size: 80, color: Colors.blueAccent),
               const SizedBox(height: 16),
               Text('Sign Up', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
               const SizedBox(height: 32),
               Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(20),
                   boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
                 ),
                 child: Column(
                   children: [
                     TextField(controller: _name, decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                     const SizedBox(height: 16),
                     TextField(controller: _email, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                     const SizedBox(height: 16),
                     TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                     const SizedBox(height: 16),
                     TextField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                     const SizedBox(height: 16),
                     DropdownButtonFormField<String>(
                       value: _role,
                       decoration: InputDecoration(labelText: 'Role', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                       items: ['Field Lead', 'Supply Partner'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                       onChanged: (v) { if (v != null) setState(() => _role = v); },
                     ),
                     if (_role == 'Field Lead') ...[
                       const SizedBox(height: 16),
                       TextField(
                         controller: _token,
                         decoration: InputDecoration(
                           labelText: 'Access Token',
                           helperText: 'Token provided by Chief Director',
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                       ),
                     ],
                     const SizedBox(height: 24),
                     SizedBox(
                       width: double.infinity, height: 50,
                       child: ElevatedButton(
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                         onPressed: _isLoading ? null : _register,
                         child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Register', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                       ),
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 16),
               TextButton(
                 onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                 child: const Text('Back to Login', style: TextStyle(color: Colors.blueAccent)),
               ),
            ],
          ),
        ),
      ),
    );
  }
}
