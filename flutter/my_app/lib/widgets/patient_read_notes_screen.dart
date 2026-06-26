import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/patient_theme.dart';

class PatientReadNotesScreen extends StatefulWidget {
  const PatientReadNotesScreen({super.key});

  @override
  State<PatientReadNotesScreen> createState() => _PatientReadNotesScreenState();
}

class _PatientReadNotesScreenState extends State<PatientReadNotesScreen> {
  List<dynamic> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final notes = await ApiService.getPatientHowToNotes();
      setState(() => _notes = notes);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 182, 223, 245),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('How To Do It',
            style: GoogleFonts.poppins(fontSize: 20 + PatientTheme.fontBoost)),
        backgroundColor: const Color.fromARGB(255, 144, 173, 247),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (_, i) {
                final n = _notes[i] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(PatientTheme.cardRadius)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n['title']?.toString() ?? '',
                            style: TextStyle(
                                fontSize: 18 + PatientTheme.fontBoost,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(n['content']?.toString() ?? '',
                            style: TextStyle(
                                fontSize: 15 + PatientTheme.fontBoost,
                                height: 1.5)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
