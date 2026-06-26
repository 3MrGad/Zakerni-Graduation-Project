import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'todo_screen.dart';
import 'medications_screen.dart';
import 'patient_reminders_screen.dart';
import 'patient_read_notes_screen.dart';
import 'chatbot_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/patient_theme.dart';
import '../widgets/start_page.dart';
import '../game/patient_game_entry.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, this.userName = 'Patient'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _patientId;
  String? _patientCode;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPatientId();
    LocationService.startTracking(intervalSeconds: 30);
  }

  Future<void> _loadPatientId() async {
    final id = await ApiService.getPatientId();
    var code = await ApiService.getPatientCode();
    if (code == null || code.isEmpty) {
      try {
        final info = await ApiService.getPatientAccountInfo();
        final patient = (info['data'] as Map?)?['patient'] as Map?;
        code = patient?['patient_code'] as String?;
        if (code != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('patient_code', code);
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _patientId = id;
        _patientCode = code;
      });
    }
  }

  void _copyPatientCode() {
    if (_patientCode == null) return;
    Clipboard.setData(ClipboardData(text: _patientCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Patient ID copied to clipboard')),
    );
  }

  @override
  void dispose() {
    LocationService.stopTracking();
    super.dispose();
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Logout',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to logout?',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.logout();
              LocationService.stopTracking();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const StartPage()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatbotTab() {
    if (_patientId == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 54, 136, 244),
        ),
      );
    }
    return FutureBuilder<List<String?>>(
      future: Future.wait([
        ApiService.getPatientName(),
        ApiService.getCaregiverName(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(255, 54, 136, 244),
            ),
          );
        }
        final patientName = snapshot.data![0] ?? widget.userName;
        final caregiverName = snapshot.data![1] ?? 'الشخص الموثوق';
        return ChatbotScreen(
          patientId: _patientId!,
          patientName: patientName,
          caregiverName: caregiverName,
        );
      },
    );
  }

  // ✅ دي اللي بتغيّر التاب الحالي - نفس اللي بيستخدمها الـ bottom bar
  void _goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 195, 202, 231),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hello, ${widget.userName} 👋',
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(221, 54, 169, 232),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                'Alzheimer Assistant',
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(255, 0, 179, 239),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              /*Text(
                'Your Memory Care Companion',
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),*/
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout,
                  color: Color.fromARGB(255, 54, 136, 244)),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: const Color.fromARGB(255, 54, 136, 244),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _goToTab,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.checklist_rounded), label: 'To Do'),
            BottomNavigationBarItem(
                icon: Icon(Icons.medication), label: 'Medications'),
            BottomNavigationBarItem(
                icon: Icon(Icons.alarm), label: 'Reminders'),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book), label: 'How To'),
            BottomNavigationBarItem(
                icon: Icon(Icons.sports_esports), label: 'Games'),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline), label: 'Chatbot'),
          ],
        ),
        // ✅ بدل IndexedStack
        body: Builder(
          builder: (context) {
            switch (_currentIndex) {
              case 0:
                return _HomeBody(
                  patientCode: _patientCode,
                  onCopyCode: _copyPatientCode,
                  userName: widget.userName,
                  onNavigate:
                      _goToTab, // ✅ ده اللي كان ناقص وبيخلي الكروت تشتغل
                );
              case 1:
                return const TodoScreen();
              case 2:
                return const MedicationsScreen();
              case 3:
                return const PatientRemindersScreen();
              case 4:
                return const PatientReadNotesScreen();
              case 5:
                return const PatientGameEntry();
              case 6:
                return _buildChatbotTab(); // ✅ بيتبنى بس لما يدوس عليه
              default:
                return const SizedBox();
            }
          },
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final Map<String, String> animations = {
    'MEDICATIONS': 'assets/animations/Medical Shield.json',
    'CHATBOT': 'assets/animations/Live chatbot.json',
    'GAMES': 'assets/animations/Game Controller.json',
    'HOW TO DO': 'assets/animations/Empty List.json',
    'TO DO LIST': 'assets/animations/Man with task list.json',
    'REMINDERS': 'assets/animations/Time management.json',
  };

  final String? patientCode;
  final VoidCallback onCopyCode;
  final String userName;
  final ValueChanged<int> onNavigate; // ✅ جديد: بيستقبل index التاب المطلوب

  //const
  _HomeBody({
    required this.patientCode,
    required this.onCopyCode,
    required this.onNavigate,
    this.userName = 'Patient',
  });

  Widget _buildItem(
      String title, IconData icon, Color color, BuildContext context,
      {int animIndex = 0, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(PatientTheme.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PatientTheme.cardRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(PatientTheme.cardRadius),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                child: animations.containsKey(title)
                    ? Lottie.asset(
                        animations[title]!,
                        width: 70,
                        height: 70,
                        repeat: true,
                      )
                    : Icon(
                        icon,
                        size: 30,
                        color: color,
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13 + PatientTheme.fontBoost,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (80 * animIndex).ms)
        .slideY(begin: 0.15, end: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (patientCode != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(PatientTheme.cardRadius),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Patient ID',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14 + PatientTheme.fontBoost,
                            color: const Color.fromARGB(255, 90, 135, 232),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share this with your caregiver',
                          style: GoogleFonts.inter(
                              fontSize: 12 + PatientTheme.fontBoost,
                              color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          patientCode!,
                          style: GoogleFonts.robotoMono(
                              fontSize: 13 + PatientTheme.fontBoost,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded,
                        size: PatientTheme.iconSize,
                        color: Color.fromARGB(255, 90, 133, 232)),
                    onPressed: onCopyCode,
                    tooltip: 'Copy Patient ID',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          /*Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 90, 126, 232),
                  Color.fromARGB(255, 74, 207, 212)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(PatientTheme.cardRadius),
              boxShadow: [
                BoxShadow(
                    color: const Color.fromARGB(255, 90, 166, 232)
                        .withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alzheimer Assistant',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18 + PatientTheme.fontBoost,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Memory Care Companion',
                  style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13 + PatientTheme.fontBoost),
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.02, 1.02),
              duration: 2.seconds),*/
          const SizedBox(height: 24),
          Text('What would you like to do?',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,

              childAspectRatio: 1.15, // زودي الرقم عشان الكارت يصغر
              // 1.2 أو 1.3 هيصغروه أكتر
              children: [
                _buildItem('MEDICATIONS', Icons.medication,
                    const Color.fromARGB(255, 111, 90, 232), context,
                    animIndex: 0, onTap: () => onNavigate(2)),
                _buildItem('TO DO LIST', Icons.checklist_rounded,
                    const Color.fromARGB(255, 106, 115, 244), context,
                    animIndex: 1, onTap: () => onNavigate(1)),
                _buildItem('HOW TO DO', Icons.menu_book,
                    const Color(0xFF9B59B6), context,
                    animIndex: 2, onTap: () => onNavigate(4)),
                _buildItem('GAMES', Icons.sports_esports, Colors.green, context,
                    animIndex: 3, onTap: () => onNavigate(5)),
                _buildItem(
                    'CHATBOT', Icons.chat_bubble_outline, Colors.teal, context,
                    animIndex: 4, onTap: () => onNavigate(6)),
                _buildItem('REMINDERS', Icons.alarm, Colors.red, context,
                    animIndex: 5, onTap: () => onNavigate(3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
