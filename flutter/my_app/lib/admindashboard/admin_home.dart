import 'package:flutter/material.dart';
import 'features_screen.dart';
import 'add_user_screen.dart';
import 'users_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int currentIndex = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    void goHome() {
      setState(() {
        currentIndex = 0;
      });
    }

    screens = [
      _buildHomeScreen(),
      UsersScreen(onBack: goHome),
      FeaturesScreen(onBack: goHome),
      UsersScreen(onBack: goHome),
    ];
  }

  void _navigateTo(int index) {
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF8B4F68);

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.black45,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        elevation: 12,
        onTap: _navigateTo,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: "Users",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.toggle_on_outlined),
            activeIcon: Icon(Icons.toggle_on),
            label: "Features",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delete_outline),
            activeIcon: Icon(Icons.delete),
            label: "Delete",
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen() {
    const primaryColor = Color(0xFF5C5FA8);
    const cardColor = Color(0xFFBCDBF2);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF5C5FA8),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Admin Dashboard",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Manage your app from here",
                style: TextStyle(fontSize: 15, color: Colors.black45),
              ),
              const SizedBox(height: 30),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  _dashboardCard(
                    title: "Users",
                    icon: Icons.people,
                    color: cardColor,
                    onTap: () => _navigateTo(1),
                  ),
                  _dashboardCard(
                    title: "Features",
                    icon: Icons.toggle_on_outlined,
                    color: const Color(0xFFDFEDC8),
                    iconColor: const Color(0xFF4A7C59),
                    textColor: const Color(0xFF4A7C59),
                    onTap: () => _navigateTo(2),
                  ),
                  _dashboardCard(
                    title: "Delete User",
                    icon: Icons.delete_outline,
                    color: const Color(0xFFFFF0F0),
                    iconColor: Colors.redAccent,
                    textColor: Colors.redAccent,
                    onTap: () => _navigateTo(3),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF57508B),
    Color textColor = const Color(0xFF4A606A),
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF8B4F68);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE7EEF3),
        elevation: 0,
        title: const Text(
          "Statistics",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          "Stats Screen",
          style: TextStyle(fontSize: 18, color: Colors.black45),
        ),
      ),
    );
  }
}
