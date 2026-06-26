import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String userType;
  final String? initialToken;
  final String? initialEmail;

  const ResetPasswordScreen({
    super.key,
    required this.userType,
    this.initialToken,
    this.initialEmail,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.initialEmail ?? '';
    _tokenCtrl.text = widget.initialToken ?? '';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.resetPassword(
        email: _emailCtrl.text.trim(),
        token: _tokenCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        role: widget.userType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password reset successfully'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
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
        ? const Color.fromARGB(255, 124, 180, 232)
        : const Color(0xFF1A7A6E);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password', style: GoogleFonts.poppins()),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(
                controller: _tokenCtrl,
                decoration: const InputDecoration(labelText: 'Reset token')),
            const SizedBox(height: 12),
            TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password')),
            const SizedBox(height: 12),
            TextField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm password')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: color),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Reset Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
