import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/patient_theme.dart';

class PatientRemindersScreen extends StatefulWidget {
  const PatientRemindersScreen({super.key});

  @override
  State<PatientRemindersScreen> createState() => _PatientRemindersScreenState();
}

class _PatientRemindersScreenState extends State<PatientRemindersScreen> {
  List<dynamic> _reminders = [];
  List<dynamic> _memories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final patientId = await ApiService.getPatientId();
      //final reminders = await ApiService.getReminders();
      List<dynamic> memories = [];
      if (patientId != null) {
        memories = await ApiService.getMemories(patientId);
      }
      setState(() {
        //_reminders = reminders;
        _memories = memories;
      });
    } catch (_) {
      setState(() {
        //_reminders = [];
        _memories = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_memories.isNotEmpty) ...[
                  Text('Memories',
                      style: GoogleFonts.poppins(
                          fontSize: 18 + PatientTheme.fontBoost,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ..._memories.map(_memoryCard),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
                ..._reminders.map(_reminderCard),
              ],
            ),
    );
  }

  Widget _memoryCard(dynamic m) {
    final map = m as Map<String, dynamic>;
    final photo = map['photo_url'] ?? map['image_url'];
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PatientTheme.cardRadius)),
      child: ListTile(
        leading: photo != null
            ? Image.network(photo.toString(),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.photo))
            : const Icon(Icons.photo, size: 40),
        title: Text(map['description']?.toString() ?? '',
            style: TextStyle(fontSize: 15 + PatientTheme.fontBoost)),
        subtitle: Text(map['memory_date']?.toString() ??
            map['created_at']?.toString() ??
            ''),
      ),
    );
  }

  Widget _reminderCard(dynamic r) {
    final map = r as Map<String, dynamic>;
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PatientTheme.cardRadius)),
      child: ListTile(
        title: Text(map['title']?.toString() ?? 'Reminder',
            style: TextStyle(fontSize: 15 + PatientTheme.fontBoost)),
        subtitle: Text(map['description']?.toString() ?? ''),
      ),
    );
  }
}
