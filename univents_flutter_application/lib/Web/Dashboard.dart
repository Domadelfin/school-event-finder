import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Login.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart'; 

final SupabaseClient supabase = Supabase.instance.client;

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
            await supabase.auth.signOut();

            // Clear session storage for web
            if (kIsWeb) {
              // Clear stored Supabase session on web
              html.window.localStorage.clear();
              html.window.sessionStorage.clear();
            }

            // Redirect to login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Login()),
            );
          }

          )
        ],
      ),
      body: Center(
        child: Text(
          'Hello, ${user?.userMetadata?["full_name"] ?? user?.email ?? "User"}!',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
