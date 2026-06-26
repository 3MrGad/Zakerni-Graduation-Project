import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/start_page.dart';
import 'patient_info.dart';
import 'memories.dart';
//import 'mental_health.dart';
import 'medication.dart';
import 'patient_todos.dart';
import 'how_to_do.dart';
import 'gps_tracking.dart';
import 'caregiver_back_handler.dart';
import '../theme/caregiver_theme.dart';
import 'caregiver_photo.dart';
import '../game/dashboard_screen.dart';
import 'package:lottie/lottie.dart';

class CaregiverHome extends StatefulWidget {
  final String userName;
  const CaregiverHome({super.key, this.userName = 'Caregiver'});

  @override
  State<CaregiverHome> createState() => CaregiverHomeState();
}

class CaregiverHomeState extends State<CaregiverHome> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    _HomeBody(onNavigate: changeTab, userName: widget.userName),
    const PatientInfo(),
    const Memories(),
    const Tracking(), // ← Real GPS now
    const HowToDo(),
    DashboardScreen(),
    //const MentalHealthPage(),
    const MedicationPage(),
  ];

  void changeTab(int index) => setState(() => _currentIndex = index);

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
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ApiService.logout();
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
        backgroundColor: CaregiverTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text('Caregiver',
              style: GoogleFonts.poppins(
                  color: CaregiverTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          actions: [
            IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: _logout,
                tooltip: 'Logout'),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE0D8F0),
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                      color: Color(0xFF5C4A8A), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: CaregiverTheme.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: changeTab,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_search), label: 'Info'),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined), label: 'Memories'),
            BottomNavigationBarItem(
                icon: Icon(Icons.location_on_outlined), label: 'GPS'),
            BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined), label: 'How To'),
            BottomNavigationBarItem(
                icon: Icon(Icons.psychology_outlined), label: 'Mental'),
            BottomNavigationBarItem(
                icon: Icon(Icons.medication_outlined), label: 'Medication'),
          ],
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final Function(int)? onNavigate;
  final String userName;
  const _HomeBody({this.onNavigate, this.userName = 'Caregiver'});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Colors.white,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, $userName',
                  style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D2D))),
              Text('Here is your care overview for today.',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              //childAspectRatio: 1.0,
              childAspectRatio: 1.15,
              children: [
                _cloudButton(context, 'Patient Info', Icons.person_search, 1,
                    onNavigate),
                _cloudButton(context, 'Memories', Icons.menu_book_outlined, 2,
                    onNavigate),
                _cloudButton(context, 'GPS Tracking',
                    Icons.location_on_outlined, 3, onNavigate),
                _cloudButton(
                    context, 'How To Do', Icons.book_outlined, 4, onNavigate),
                _cloudButton(context, 'Mental Health',
                    Icons.psychology_outlined, 5, onNavigate),
                _cloudButton(context, 'Medication', Icons.medication_outlined,
                    6, onNavigate),
                _cloudButton(context, 'Patient Tasks', Icons.checklist_rounded,
                    -1, onNavigate,
                    onTasks: true, userName: userName),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CaregiverPeopleScreen(),
                      )),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: CaregiverTheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Lottie.asset(
                            'assets/animations/Mental Health Awareness.json',
                            width: 60,
                            height: 60,
                            repeat: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Memory Game',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final Map<String, String> animations = {
  'Patient Info':
      'assets/animations/Seo specialists work on high-quality organic search traffic.json',
  'Memories': 'assets/animations/Time management.json',
  'GPS Tracking': 'assets/animations/Splash Gif.json',
  'How To Do': 'assets/animations/Empty List.json',
  'Mental Health': 'assets/animations/Mental Health.json',
  'Medication': 'assets/animations/Medical Shield.json',
  'Patient Tasks': 'assets/animations/Man with task list.json',
  'Memory Game': 'assets/animations/Mental Health Awareness.json',
};

Widget _cloudButton(BuildContext context, String title, IconData icon,
    int index, Function(int)? onNavigate,
    {bool onTasks = false, String userName = 'Caregiver'}) {
  return GestureDetector(
    onTap: () {
      if (onTasks) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CaregiverBackHandler(
              userName: userName,
              child: const PatientTodosScreen(),
            ),
          ),
        );
        return;
      }
      onNavigate?.call(index);
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
          color: CaregiverTheme.accent.withOpacity(0.35),
          borderRadius: BorderRadius.circular(CaregiverTheme.cardRadius)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: animations.containsKey(title)
                ? Lottie.asset(
                    animations[title]!,
                    width: 60,
                    height: 60,
                    repeat: true,
                  )
                : Icon(
                    icon,
                    size: 28,
                    color: const Color(0xFF5C4A8A),
                  ),
          ),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D))),
        ],
      ),
    ),
  );
}
