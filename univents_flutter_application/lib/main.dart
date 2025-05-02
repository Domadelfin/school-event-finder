import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Web/Login.dart';
import 'package:univents_flutter_application/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: env.SUPABASE_URL,
    anonKey: env.SUPABASE_ANON_KEY
    );

  final supabase = Supabase.instance.client;

  final uri = Uri.base;

  if (kIsWeb &&
      (uri.queryParameters.containsKey('access_token') ||
          uri.queryParameters.containsKey('refresh_token') ||
          uri.queryParameters.containsKey('error'))) {
    try {
      await supabase.auth.getSessionFromUrl(uri);

      html.window.history.replaceState(null, '', '/');
    } catch (e) {
      debugPrint('OAuth session restoration failed: $e');
    }
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Login(),
      debugShowCheckedModeBanner: false,
    );
  }
}
