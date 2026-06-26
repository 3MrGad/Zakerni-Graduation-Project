import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import '../caregiver/caregiver_home.dart';
import '../services/api_service.dart';
import '../services/secure_auth_service.dart';

class AuthScreen extends StatefulWidget {
  final String userType;
  const AuthScreen({super.key, required this.userType});

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
      _showSignUp ? _controller.forward() : _controller.reverse();
    });
  }

  Color getPrimaryColor() => widget.userType == 'patient'
      ? const Color.from(alpha: 1, red: 0.129, green: 0.588, blue: 0.953)
      : const Color.fromRGBO(26, 122, 110, 1);
  Color getLightColor() => widget.userType == 'patient'
      ? Colors.blue[100]!.withOpacity(0.2)
      : const Color(0xFFF0FAF8);
  Color getDarkColor() => widget.userType == 'patient'
      ? const Color.from(alpha: 1, red: 0.129, green: 0.588, blue: 0.953)
      : const Color(0xFF145C52);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final primaryColor = getPrimaryColor();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userType == 'patient' ? 'Patient Portal' : 'Caregiver Portal',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: getDarkColor()),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [getLightColor(), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: size.height * 0.25,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 130,
                        width: 130,
                        child: Lottie.asset(
                          widget.userType == 'patient'
                              ? 'assets/animations/brain.json'
                              : 'assets/animations/Funny brain.json',
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        widget.userType == 'patient'
                            ? 'Patient Account'
                            : 'Caregiver Account',
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: getDarkColor()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _flipAnim,
                  builder: (context, child) {
                    final angle = _flipAnim.value * math.pi;
                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle);

                    Widget currentCard = _showSignUp
                        ? SignUpForm(
                            onToggle: toggleView,
                            userType: widget.userType,
                            primaryColor: primaryColor)
                        : LoginForm(
                            onToggle: toggleView,
                            userType: widget.userType,
                            primaryColor: primaryColor);

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
                        constraints: const BoxConstraints(maxWidth: 500),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 25,
                                offset: const Offset(0, 10))
                          ],
                          border: Border.all(
                              color: primaryColor.withOpacity(0.2), width: 1.5),
                        ),
                        child: currentCard,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOGIN FORM — calls real API
// ═══════════════════════════════════════════════════════════════════════════════
class LoginForm extends StatefulWidget {
  final VoidCallback onToggle;
  final String userType;
  final Color primaryColor;
  const LoginForm(
      {required this.onToggle,
      required this.userType,
      required this.primaryColor,
      super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('remember_me') == true) {
      setState(() {
        _rememberMe = true;
        _emailCtrl.text = prefs.getString('saved_email') ?? '';
        _passCtrl.text = prefs.getString('saved_password') ?? '';
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final res = await ApiService.login(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
        rememberMe: _rememberMe,
      );
      //print(res);

      final body = (res['data'] is Map<String, dynamic>)
          ? res['data'] as Map<String, dynamic>
          : res;
      final user = body['user'] as Map<String, dynamic>;
      final role = user['role'] as String;
      final token = body['token'] as String;

      if (role != widget.userType) {
        throw Exception(
            'This account is a $role account. Please use the ${role == 'patient' ? 'Patient' : 'Caregiver'} portal.');
      }

      int? patientId;
      int? caregiverId;
      String? patientCode;
      final roleData = body['data'];
      if (role == 'patient' && roleData is Map<String, dynamic>) {
        patientId = roleData['patient_id'] as int?;
        patientCode = roleData['patient_code'] as String? ??
            body['patient_code'] as String?;
      } else if (role == 'caregiver' && roleData is Map<String, dynamic>) {
        caregiverId = roleData['caregiver_id'] as int?;
      }
      patientCode ??= body['patient_code'] as String?;

      final expiresAt = body['expires_at'] as String?;

      await ApiService.saveSession(
        token: token,
        role: role,
        userId: user['id'] as int,
        name: user['name'] as String,
        patientId: patientId,
        caregiverId: caregiverId,
        patientCode: patientCode,
        expiresAt: expiresAt,
      );

      if (_rememberMe) {
        await SecureAuthService.saveRememberedSession(
          token: token,
          role: role,
          expiresAt: expiresAt,
        );
      } else {
        await SecureAuthService.clearRememberedSession();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Login Successful ✅'),
            backgroundColor: widget.primaryColor),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'caregiver'
              ? CaregiverHome(userName: user['name'] as String)
              : HomeScreen(userName: user['name'] as String),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Sign In',
            style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: widget.primaryColor)),
        const SizedBox(height: 6),
        Text(
          widget.userType == 'patient'
              ? 'Access your personal memory care tools'
              : 'Access your patient management dashboard',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(
                  controller: _emailCtrl,
                  hint: 'Email Address',
                  icon: Icons.email_rounded,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildField(
                  controller: _passCtrl,
                  hint: 'Password',
                  icon: Icons.lock_rounded,
                  obscure: true),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? false),
                        activeColor: widget.primaryColor,
                      ),
                      Text('Remember me',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.grey[700])),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ForgotPasswordScreen(userType: widget.userType)),
                    ),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text('Forgot password?',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: widget.primaryColor,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.login,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text('Sign In',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?",
                      style: GoogleFonts.inter(
                          fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: widget.onToggle,
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text('Create Account',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.primaryColor)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      TextInputType? keyboard,
      bool obscure = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      style: GoogleFonts.inter(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
        prefixIcon:
            Icon(icon, color: widget.primaryColor.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.primaryColor, width: 2)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIGN UP FORM — calls real API
// ═══════════════════════════════════════════════════════════════════════════════
class SignUpForm extends StatefulWidget {
  final VoidCallback onToggle;
  final String userType;
  final Color primaryColor;
  const SignUpForm(
      {required this.onToggle,
      required this.userType,
      required this.primaryColor,
      super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _fnameCtrl = TextEditingController();
  final _lnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _patientIdCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _fnameCtrl.dispose();
    _lnameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _phoneCtrl.dispose();
    _patientIdCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
      Map<String, dynamic> res;
      if (widget.userType == 'patient') {
        res = await ApiService.registerPatient(
          fname: _fnameCtrl.text.trim(),
          lname: _lnameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      } else {
        final code = _patientIdCtrl.text.trim();
        final uuidRegex = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        );
        if (!uuidRegex.hasMatch(code)) {
          throw Exception('Enter a valid Patient ID (UUID format).');
        }
        res = await ApiService.registerCaregiver(
          fname: _fnameCtrl.text.trim(),
          lname: _lnameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          patientCode: code,
        );
      }

      if (!mounted) return;
      if (widget.userType == 'patient') {
        final inner =
            (res['data'] is Map) ? res['data'] as Map<String, dynamic> : res;
        final code = inner['patient_code']?.toString() ?? '';
        if (code.isNotEmpty) {
          await ApiService.saveSession(
            token: inner['token'] as String? ?? '',
            role: 'patient',
            userId: (inner['user'] as Map?)?['id'] as int? ?? 0,
            name: (inner['user'] as Map?)?['name'] as String? ?? '',
            patientId: inner['patient_id'] as int?,
            patientCode: code,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Your Patient ID: $code — share it with your caregiver.'),
              backgroundColor: widget.primaryColor,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Account created successfully! ✅ Please sign in.'),
            backgroundColor: widget.primaryColor),
      );
      widget.onToggle(); // flip back to login
    } catch (e) {
      if (!mounted) return;
      var msg = e.toString().replaceFirst('Exception: ', '');
      if (e is ApiException && e.statusCode == 404) {
        msg = 'Patient ID not found. Ask your patient to share their ID.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Create Account',
            style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: widget.primaryColor)),
        const SizedBox(height: 6),
        Text(
          widget.userType == 'patient'
              ? 'Start your personal memory care journey'
              : 'Begin managing your patient',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _buildField(
                          controller: _fnameCtrl,
                          hint: 'First Name',
                          icon: Icons.person_rounded)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildField(
                          controller: _lnameCtrl,
                          hint: 'Last Name',
                          icon: Icons.person_outline_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(
                  controller: _emailCtrl,
                  hint: 'Email Address',
                  icon: Icons.email_rounded,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildField(
                  controller: _passCtrl,
                  hint: 'Password',
                  icon: Icons.lock_rounded,
                  obscure: true),
              const SizedBox(height: 16),
              _buildField(
                  controller: _confirmCtrl,
                  hint: 'Confirm Password',
                  icon: Icons.lock_outline_rounded,
                  obscure: true),
              if (widget.userType == 'caregiver') ...[
                const SizedBox(height: 16),
                _buildField(
                  controller: _patientIdCtrl,
                  hint: "Enter your patient's ID *",
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 16),
                _buildField(
                    controller: _phoneCtrl,
                    hint: 'Phone (optional)',
                    icon: Icons.phone_rounded,
                    keyboard: TextInputType.phone,
                    required: false),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_add,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text('Create Account',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: widget.onToggle,
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text('Sign In',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.primaryColor)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      TextInputType? keyboard,
      bool obscure = false,
      bool required = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: (v) =>
          (required && (v == null || v.isEmpty)) ? 'Required' : null,
      style: GoogleFonts.inter(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
        prefixIcon:
            Icon(icon, color: widget.primaryColor.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.primaryColor, width: 2)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
    );
  }
}
