// lib/widgets/auth_pages.dart
// Animated Login / Create Account pages for "Alzheimer Assistant" project
// Updated to fix flip mirror issue and enlarge animation

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class AuthScreen extends StatefulWidget {
  final String userType;
  const AuthScreen({required this.userType, super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnim;
  bool _showSignUp = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _flipAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleView() {
    setState(() {
      _showSignUp = !_showSignUp;
      if (_showSignUp) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          const _AnimatedBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: size.height * 0.28, // أكبر شويه
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Alzheimer Assistant',
                              style: GoogleFonts.poppins(
                                  fontSize: 24, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 120, // حجم الانميشن أكبر
                            width: 120,
                            child: LottieBuilder.asset(
                              'assets/animations/brain.json',
                              fit: BoxFit.contain,
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _flipAnim,
                      builder: (context, child) {
                        final angle = _flipAnim.value * math.pi;
                        final transform = Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle);

                        Widget currentCard = _showSignUp
                            ? SignUpForm(onToggle: toggleView)
                            : LoginForm(onToggle: toggleView);

                        // flip internal content if rotated more than 90°
                        if (_flipAnim.value >= 0.5) {
                          currentCard = Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: currentCard,
                          );
                        }

                        return Transform(
                          transform: transform,
                          alignment: Alignment.center,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 520),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: currentCard,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _showSignUp
                          ? 'Create an account to save memories and share with caregivers.'
                          : 'Welcome back — continue to access memory exercises and reminders.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// -------------------------- LoginForm --------------------------
class LoginForm extends StatefulWidget {
  final VoidCallback onToggle;
  const LoginForm({required this.onToggle, super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _loading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Logged in (simulated)')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Sign in',
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                  controller: _emailCtrl,
                  hint: 'Email',
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildTextField(
                  controller: _passCtrl, hint: 'Password', obscure: true),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.login),
                            SizedBox(width: 8),
                            Text('Login')
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                      onPressed: () {}, child: const Text('Forgot password?')),
                  const SizedBox(width: 6),
                  TextButton(
                      onPressed: widget.onToggle,
                      child: const Text('Create account')),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      TextInputType? keyboard,
      bool obscure = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }
}

// -------------------------- SignUpForm --------------------------
class SignUpForm extends StatefulWidget {
  final VoidCallback onToggle;
  const SignUpForm({required this.onToggle, super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created (simulated)')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Create account',
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(controller: _nameCtrl, hint: 'Full name'),
              const SizedBox(height: 10),
              _buildTextField(
                  controller: _emailCtrl,
                  hint: 'Email',
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _buildTextField(
                  controller: _passCtrl, hint: 'Password', obscure: true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.person_add),
                            SizedBox(width: 8),
                            Text('Create account')
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                      onPressed: widget.onToggle, child: const Text('Sign in')),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      TextInputType? keyboard,
      bool obscure = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }
}

// -------------------------- Animated Background --------------------------
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground({super.key});

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          painter: _BGPainter(_ctrl.value),
          child: Container(),
        );
      },
    );
  }
}

class _BGPainter extends CustomPainter {
  final double t;
  _BGPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFe6f0ff), Color(0xFFf7f7ff)],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    final bubblePaint = Paint()..color = Colors.lightBlue.withOpacity(0.12);
    final w = size.width;
    final h = size.height;

    void drawBubble(double cx, double cy, double r, double phase) {
      final dx = 10 * (0.5 - (t + phase) % 1);
      canvas.drawCircle(Offset(cx + dx, cy), r, bubblePaint);
    }

    drawBubble(w * 0.15, h * 0.2, 50, 0.0);
    drawBubble(w * 0.8, h * 0.18, 38, 0.2);
    drawBubble(w * 0.25, h * 0.8, 60, 0.6);

    final path = Path();
    final baseY = h * 0.78;
    path.moveTo(0, h);
    path.lineTo(0, baseY);
    for (double x = 0; x <= w; x += 20) {
      final y = baseY + 12 * (1 + (Math.sin((x / w * 2 * 3.14159) + t * 3)));
      path.quadraticBezierTo(x + 10, y, x + 20, baseY);
    }
    path.lineTo(w, h);
    path.close();

    final wavePaint = Paint()
      ..color =
          const Color.from(alpha: 1, red: 0.129, green: 0.588, blue: 0.953)
              .withOpacity(0.06);
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _BGPainter old) => old.t != t;
}

class Math {
  static double sin(double x) => math.sin(x);
}
