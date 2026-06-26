import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'game_api_service.dart';
import 'game_screen.dart';
import 'theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool   _loading = false;
  String _error   = '';

  // ── للـ Web: المريض بيدخل الـ patient_id يدوياً مؤقتاً
  // (لأنه مش عنده login screen خاص بيه في الـ Memory Game)
  final _idCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    final idText = _idCtrl.text.trim();
    final patientId = int.tryParse(idText);

    if (patientId == null || patientId <= 0) {
      setState(() => _error = 'أدخل رقم مريض صحيح');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    try {
      // تحقق إن الـ Flask شغال وفيه ناس مضافين
      final res = await GameApiService.startGame(patientId);

      if (res['error'] != null) {
        setState(() {
          _error   = res['error'] as String;
          _loading = false;
        });
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            patientId:   patientId,
            patientName: 'Patient #$patientId',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error   = 'تعذر الاتصال بالسيرفر.\nتأكد إن Flask شغال على port 5000\nوإن CORS مفعّل.\n\nError: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.cream,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 64))
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 12),

                  Text('حكايات ما بتتنسيش',
                    style: GoogleFonts.lora(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      height: 1.2,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                  const SizedBox(height: 8),

                  Text(
                    'تمارين تذكر الوجوه المألوفة',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.6,
                    ),
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 36),

                  Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ابدأ التدريب',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.charcoal,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'أدخل رقم المريض (patient_id من قاعدة البيانات)',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _idCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Patient ID',
                            hintText:  'مثال: 1',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        ),

                        if (_error.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE8E4),
                              border: const Border(
                                left: BorderSide(color: AppColors.coral, width: 4),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(children: [
                              const Text('⚠️'),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_error,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: const Color(0xFF842029),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ],

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _startGame,
                            child: _loading
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                  )
                                : Text('ابدأ التدريب ←',
                                    style: GoogleFonts.nunito(
                                      fontSize: 17, fontWeight: FontWeight.w800),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                  const SizedBox(height: 24),

                  // Debug info
                  Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🔧 إعدادات الاتصال',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text('Flask URL: $kFlaskUrl',
                          style: GoogleFonts.nunito(
                            fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          'لو مشتغلش: افتح Chrome DevTools (F12) → Console وشوف الـ error',
                          style: GoogleFonts.nunito(
                            fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
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