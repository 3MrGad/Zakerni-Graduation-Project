import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'services/secure_auth_service.dart';
import 'widgets/start_page.dart';
import 'widgets/home_screen.dart';
import 'caregiver/caregiver_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (skip on web platform)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  // Initialize notifications (FCM + local)
  await NotificationService.init();

  runApp(const AlzheimerApp());
}

class AlzheimerApp extends StatelessWidget {
  const AlzheimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alzheimer Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 0, 81, 255)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
              color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      home: const SplashRouter(),
    );
  }
}

// SplashRouter: checks if already logged in and routes accordingly
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});
  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    String? role = prefs.getString('user_role');
    final name = prefs.getString('user_name') ?? '';

    if (await SecureAuthService.isRememberMeEnabled()) {
      if (await SecureAuthService.isRememberedSessionExpired()) {
        await SecureAuthService.clearRememberedSession();
        await ApiService.clearSession();
        token = null;
        role = null;
      } else {
        token ??= await SecureAuthService.getToken();
        role ??= await SecureAuthService.getRole();
        if (token != null && token.isNotEmpty) {
          await prefs.setString('auth_token', token);
          if (role != null) await prefs.setString('user_role', role);
        }
      }
    } else if (await ApiService.isSessionExpired()) {
      await ApiService.clearSession();
      token = null;
      role = null;
    }

    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Widget home;

      if (role == 'caregiver') {
        home = CaregiverHome(userName: name);
      } else {
        home = HomeScreen(userName: name);
      }

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => home));
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StartPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.lightBlue[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 250,
                width: 250,
                child: Lottie.asset(
                  'assets/animations/start.json',
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Alzheimer Assistant',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
