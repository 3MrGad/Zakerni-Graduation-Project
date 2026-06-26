import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import 'game_screen.dart';
import 'theme.dart';

/// شاشة الـ Patient لبدء اللعبة — بدون login تاني
/// بتجيب الـ patient_id من SharedPreferences تلقائياً
class PatientGameEntry extends StatefulWidget {
  const PatientGameEntry({super.key});

  @override
  State<PatientGameEntry> createState() => _PatientGameEntryState();
}

class _PatientGameEntryState extends State<PatientGameEntry> {
  bool _loading = false;
  String? _error;

  Future<void> _startGame() async {
    setState(() { _loading = true; _error = null; });

    try {
      // جيب الـ patient_id من SharedPreferences (اتحفظ وقت الـ login)
      final patientId = await ApiService.getPatientId();
      final name      = await ApiService.getUserName() ?? 'Patient';

      if (patientId == null) {
        setState(() {
          _error   = 'لم يتم العثور على بيانات المريض. يرجى تسجيل الدخول مجدداً.';
          _loading = false;
        });
        return;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            patientId:   patientId,
            patientName: name,
          ),
        ),
      );

      setState(() => _loading = false);

    } catch (e) {
      setState(() {
        _error   = 'حدث خطأ. تأكد من الاتصال بالسيرفر.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('🧠', style: TextStyle(fontSize: 64))
                    .animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 12),

                Text('حكايات ما بتتنسيش',
                  style: GoogleFonts.lora(
                    fontSize: 36, fontWeight: FontWeight.w700,
                    color: AppColors.navy, height: 1.2,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                const SizedBox(height: 8),

                Text(
                  'تمارين تذكر الوجوه المألوفة',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 15, color: Colors.grey[600], height: 1.6,
                  ),
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 36),

                Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: const Offset(0, 6)),
                    ],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ابدأ اللعبه',
                        style: GoogleFonts.nunito(
                          fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.charcoal,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'اضغط الزر لبدء اللعبة.',
                        style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[600], height: 1.5),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8E4),
                            border: const Border(left: BorderSide(color: AppColors.coral, width: 4)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            const Text('⚠️'),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!,
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700, color: const Color(0xFF842029),
                              ),
                            )),
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
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text('ابدأ التدريب →',
                                  style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                const SizedBox(height: 24),

                Wrap(
                  spacing: 10, runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: const [
                    _Pill('ذكريات العائلة 👨‍👩‍👧‍👦', AppColors.sage,  Color(0xFFA4C3B2)),
                    _Pill('لحظات جميلة📷',  AppColors.amber, AppColors.warm),
                    _Pill('إنجازاتك⭐',       AppColors.coral, Color(0xFFF5C6B8)),
                  ],
                ).animate().fadeIn(delay: 550.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color  textColor;
  final Color  borderColor;

  const _Pill(this.text, this.textColor, this.borderColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(text,
        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }
}