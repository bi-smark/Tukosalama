import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'widgets/app_layout.dart';
import 'auth/login_page.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with your project options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const TukoSalamaApp());
}

class TukoSalamaApp extends StatelessWidget {
  const TukoSalamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TukoSalama',

      // FORCE LIGHT THEME: Removes all dark mode logic
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        useMaterial3: true,
        brightness: Brightness.light, // Ensures a clean, consistent look
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Modern off-white
      ),

      routes: {'/login': (context) => const LoginPage()},
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return FutureBuilder<TukoUser?>(
              future: AuthService().getTukoUser(snapshot.data!.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (userSnapshot.hasData && userSnapshot.data != null) {
                  return AppLayout(user: userSnapshot.data!);
                }
                return const LoginPage();
              },
            );
          }
          return const LoginPage();
        },
      ),
    );
  }
}
