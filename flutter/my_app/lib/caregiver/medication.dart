import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

/// Caregiver manages medications for their linked patient(s).
class MedicationPage extends StatefulWidget {
  const MedicationPage({super.key});

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  List<dynamic> _patients = [];
  List<dynamic> _meds = [];
  List<dynamic> _takeLogs = [];
  dynamic _selectedPatient;
  bool _loading = true;
  bool _loadingMeds = false;
  bool _adding = false;

  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: '08:00');
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _freqCtrl.dispose();
    _reasonCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  int? get _patientId => _selectedPatient?['patient_id'] as int?;

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      final patients = await ApiService.getMyPatients();
      final savedId = await ApiService.getSelectedPatientId();
      setState(() {
        _patients = patients;
        if (patients.isNotEmpty) {
          _selectedPatient = patients.firstWhere(
            (p) => p['patient_id'] == savedId,
            orElse: () => patients.first,
          );
        }
      });
      if (_patientId != null) {
        await ApiService.setSelectedPatientId(_patientId!);
        await _loadMeds();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMeds() async {
    if (_patientId == null) return;
    setState(() => _loadingMeds = true);
    try {
      final meds = await ApiService.getMedications(patientId: _patientId);
      final logs = await ApiService.getMedicationLogs();
      setState(() {
        _meds = meds;
        _takeLogs = logs;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loadingMeds = false);
    }
  }

  Future<void> _addMedication() async {
    if (_patientId == null || _nameCtrl.text.trim().isEmpty) return;
    setState(() => _adding = true);
    try {
      await ApiService.addMedication(
        medName: _nameCtrl.text.trim(),
        dosage: _doseCtrl.text.trim().isEmpty ? null : _doseCtrl.text.trim(),
        frequency: _freqCtrl.text.trim().isEmpty ? null : _freqCtrl.text.trim(),
        reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
        scheduledTime: _timeCtrl.text.trim(),
        patientId: _patientId,
      );
      _nameCtrl.clear();
      _doseCtrl.clear();
      _freqCtrl.clear();
      _reasonCtrl.clear();
      if (mounted) Navigator.pop(context);
      await _loadMeds();
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        _showError('This medicine is already added.');
      } else {
        _showError(e.message);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _adding = false);
    }
  }

  Future<void> _deleteMed(int medId) async {
    try {
      await ApiService.deleteMedication(medId, patientId: _patientId);
      await _loadMeds();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg.replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Patient Medication', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF7A5C69))),
            const SizedBox(height: 16),
            _field(_nameCtrl, 'Medication name *'),
            const SizedBox(height: 12),
            _field(_doseCtrl, 'Dosage (e.g. 500mg)'),
            const SizedBox(height: 12),
            _field(_freqCtrl, 'Frequency (e.g. Once daily)'),
            const SizedBox(height: 12),
            _field(_reasonCtrl, 'Reason (optional)'),
            const SizedBox(height: 12),
            _field(_timeCtrl, 'Reminder time (HH:MM, 24h)'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _adding ? null : _addMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A5C69),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _adding
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Save for Patient', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF5F0F4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF7A5C69)));
    }

    if (_patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('No patient linked', style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Text(
                'Enter your patient\'s UUID Patient ID during caregiver registration to manage medications.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8FB),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF7A5C69),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_patients.length > 1)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButton<dynamic>(
                  isExpanded: true,
                  value: _selectedPatient,
                  underline: const SizedBox(),
                  items: _patients
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p['name'] as String? ?? 'Patient', style: GoogleFonts.inter()),
                          ))
                      .toList(),
                  onChanged: (p) async {
                    setState(() => _selectedPatient = p);
                    if (_patientId != null) await ApiService.setSelectedPatientId(_patientId!);
                    await _loadMeds();
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Medications for ${_selectedPatient?['name'] ?? 'Patient'}",
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'You add medicines — the patient only sees reminders',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loadingMeds
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF7A5C69)))
                  : RefreshIndicator(
                      onRefresh: _loadMeds,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_meds.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text('No medications yet. Tap + to add.', style: GoogleFonts.inter(color: Colors.grey))),
                            )
                          else
                            ..._meds.map((med) {
                              final m = med as Map<String, dynamic>;
                              return Dismissible(
                                key: Key('cg_med_${m['med_id']}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) => _deleteMed(m['med_id'] as int),
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF7A5C69).withOpacity(0.1),
                                      child: const Icon(Icons.medication_outlined, color: Color(0xFF7A5C69)),
                                    ),
                                    title: Text(m['med_name'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      [
                                        if (m['dosage'] != null) 'Dose: ${m['dosage']}',
                                        if (m['frequency'] != null) 'When: ${m['frequency']}',
                                      ].join(' • '),
                                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          if (_takeLogs.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text('Taken Confirmation', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            ..._takeLogs.map((log) {
                              final l = log as Map<String, dynamic>;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                                  title: Text(l['medicine_name']?.toString() ?? 'Medicine'),
                                  subtitle: Text(
                                    '${l['patient_name'] ?? ''} • ${l['taken_at'] ?? ''}',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

