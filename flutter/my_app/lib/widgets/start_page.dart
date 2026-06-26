import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'auth_screen.dart';
import '../admindashboard/admin_login_screen.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

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
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // العنوان والأنميشن
                  Column(
                    children: [
                      Text(
                        'Alzheimer Assistant',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Memory Care Companion',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.blueGrey[700],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // الأنميشن
                      Container(
                        height: 220,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Lottie.asset(
                          'assets/animations/brain.json',
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminLoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      label: const Text(
                        "Admin",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          //backgroundColor: Color.fromARGB(255, 102, 214, 190),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // كارت المريض
                  _UserTypeCard(
                    title: 'I am a Patient',
                    subtitle:
                        'Access memory exercises, reminders, and track progress',
                    icon: Icons.person_rounded,
                    iconColor: Colors.blue,
                    backgroundColor: Colors.blue[50]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AuthScreen(userType: 'patient'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // كارت الراعي
                  _UserTypeCard(
                    title: 'I am a Caregiver',
                    subtitle:
                        'Manage patients, monitor activities, and provide support',
                    icon: Icons.medical_services_rounded,
                    iconColor: Colors.teal,
                    backgroundColor: Colors.teal[50]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AuthScreen(userType: 'caregiver'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // نص تذييلي
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Join thousands who have found support in their memory care journey',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// كارت نوع المستخدم
class _UserTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: iconColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: iconColor,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
