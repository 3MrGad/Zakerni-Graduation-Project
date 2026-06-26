import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String userType;
  const ForgotPasswordScreen({super.key, this.userType = 'patient'});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService.forgotPassword(_emailCtrl.text.trim(), widget.userType);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Reset link sent. Check your email for the token.'),
          backgroundColor: widget.userType == 'patient'
              ? const Color.fromARGB(255, 124, 151, 232)
              : const Color(0xFF1A7A6E),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            userType: widget.userType,
            initialEmail: _emailCtrl.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.userType == 'patient'
        ? const Color.fromARGB(255, 124, 149, 232)
        : const Color(0xFF1A7A6E);

    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password',
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Reset your password',
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_rounded),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _send,
                style: ElevatedButton.styleFrom(backgroundColor: color),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Send Reset Link',
                        style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
