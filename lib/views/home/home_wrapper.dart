import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'field_lead_dashboard.dart';
import 'supplier_dashboard.dart';
import 'director_dashboard.dart';

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.firebaseUser == null) {
      return const LoginScreen();
    }

    // Use FutureBuilder to wait for User Document from Firestore globally to avoid async race conditions
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(auth.firebaseUser!.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Could not load user data.'),
                  ElevatedButton(
                    onPressed: () => context.read<AuthProvider>().signOut(),
                    child: const Text('Logout'),
                  )
                ],
              ),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        // Lowercasing to ensure capitalization doesn't break routing
        final String role = (userData['role'] ?? '').toString().toLowerCase();
        final String email = (userData['email'] ?? '').toString().toLowerCase();

        if (email == 'chief@aidpoint.com' || role.contains('director')) {
          return const DirectorDashboard();
        } else if (role.contains('supply') || role.contains('partner')) {
          return const SupplierDashboard();
        } else {
          return const FieldLeadDashboard(); // Defaults properly for 'field lead'
        }
      },
    );
  }
}
