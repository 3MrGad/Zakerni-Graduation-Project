import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});
  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _meds = [];
  List<dynamic> _logs = [];
  bool _loadingMeds = true;
  bool _loadingLogs = true;
  bool _isPatient = true;

  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initRole();
  }

  Future<void> _initRole() async {
    final role = await ApiService.getRole();
    setState(() => _isPatient = role == 'patient');
    await _loadMeds();
    await _loadLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _freqCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeds() async {
    setState(() => _loadingMeds = true);
    try {
      final meds = await ApiService.getMedications();
      setState(() => _meds = meds);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loadingMeds = false);
    }
  }

  Future<void> _loadLogs() async {
    setState(() => _loadingLogs = true);
    try {
      final logs = await ApiService.getMedicationLogs();
      setState(() => _logs = logs);
    } catch (e) {
      // Logs might be empty for new patients - not critical
      setState(() => _logs = []);
    } finally {
      setState(() => _loadingLogs = false);
    }
  }

  Future<void> _markTaken(int logId) async {
    try {
      await ApiService.markMedicationTaken(logId);
      await _loadLogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Marked as taken!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _deleteMed(int medId) async {
    try {
      await ApiService.deleteMedication(medId);
      await _loadMeds();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _addMed() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _adding = true);
    try {
      await ApiService.addMedication(
        medName: _nameCtrl.text.trim(),
        dosage: _doseCtrl.text.trim().isEmpty ? null : _doseCtrl.text.trim(),
        frequency: _freqCtrl.text.trim().isEmpty ? null : _freqCtrl.text.trim(),
        reason:
            _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
      );
      _nameCtrl.clear();
      _doseCtrl.clear();
      _freqCtrl.clear();
      _reasonCtrl.clear();
      Navigator.pop(context);
      await _loadMeds();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _adding = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg.replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red),
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Medication',
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE57C00))),
            const SizedBox(height: 16),
            _field(_nameCtrl, 'Medication name *', Icons.medication),
            const SizedBox(height: 12),
            _field(_doseCtrl, 'Dosage (e.g. 500mg)', Icons.scale),
            const SizedBox(height: 12),
            _field(_freqCtrl, 'Frequency (e.g. Once daily)', Icons.schedule),
            const SizedBox(height: 12),
            _field(_reasonCtrl, 'Reason (optional)', Icons.note),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _adding ? null : _addMed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 62, 124, 239),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _adding
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text('Save Medication',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon) =>
      TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color.fromARGB(255, 0, 118, 229)),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color.fromARGB(255, 0, 46, 229), width: 2)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false, // بيشيل السهم

        backgroundColor: Colors.white,
        elevation: 1,

        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromARGB(255, 0, 160, 229),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color.fromARGB(255, 0, 99, 229),
          tabs: const [
            Tab(
              text: 'My Medications',
              icon: Icon(Icons.medication),
            ),
            Tab(
              text: "Today's Reminders",
              icon: Icon(Icons.alarm),
            ),
          ],
        ),
      ),
      floatingActionButton: _isPatient
          ? null
          : FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: const Color.fromARGB(255, 0, 99, 229),
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: My Medications ───────────────────────────────────────────
          _loadingMeds
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 0, 122, 229)))
              : RefreshIndicator(
                  onRefresh: _loadMeds,
                  child: _meds.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.medication_liquid,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No medications added',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey, fontSize: 18)),
                              Text(
                                _isPatient
                                    ? 'Your caregiver will add medications for you'
                                    : 'Tap + to add medications',
                                style:
                                    GoogleFonts.inter(color: Colors.grey[400]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _meds.length,
                          itemBuilder: (ctx, i) {
                            final med = _meds[i] as Map<String, dynamic>;
                            final taken =
                                med['is_taken'] == true || med['is_taken'] == 1;
                            final card = Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                              color: taken ? Colors.green.shade50 : null,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 0, 164, 229)
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    taken
                                        ? Icons.check_circle
                                        : Icons.medication,
                                    color: taken
                                        ? Colors.green
                                        : const Color.fromARGB(
                                            255, 0, 195, 229),
                                  ),
                                ),
                                title: Text(med['med_name'] as String,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((med['dosage'] as String?) != null)
                                      Text('Dose: ${med['dosage']}',
                                          style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.grey[600])),
                                    if ((med['frequency'] as String?) != null)
                                      Text('When: ${med['frequency']}',
                                          style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.grey[600])),
                                    if ((med['reason'] as String?) != null)
                                      Text('For: ${med['reason']}',
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey[500])),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                            if (_isPatient) {
                              if (taken) return card;
                              return Dismissible(
                                key: Key('take-${med['med_id']}'),
                                direction: DismissDirection.startToEnd,
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(16)),
                                  child: const Icon(Icons.check,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (_) async {
                                  try {
                                    await ApiService.markMedicationTakenById(
                                        med['med_id'] as int);
                                    await _loadMeds();
                                    return false;
                                  } catch (e) {
                                    _showError(e.toString());
                                    return false;
                                  }
                                },
                                child: card,
                              );
                            }
                            return Dismissible(
                              key: Key(med['med_id'].toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) =>
                                  _deleteMed(med['med_id'] as int),
                              child: card,
                            );
                          },
                        ),
                ),

          // ── Tab 2: Today's Reminder Logs ───────────────────────────────────
          _loadingLogs
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 0, 149, 229)))
              : RefreshIndicator(
                  onRefresh: _loadLogs,
                  child: _logs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.alarm_off,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text("No reminders today",
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey, fontSize: 18)),
                              Text("Reminders appear here when scheduled",
                                  style: GoogleFonts.inter(
                                      color: Colors.grey[400])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _logs.length,
                          itemBuilder: (ctx, i) {
                            final log = _logs[i] as Map<String, dynamic>;
                            final status = log['status'] as String;
                            final schedule =
                                log['schedule'] as Map<String, dynamic>?;
                            final medication = schedule?['medication']
                                as Map<String, dynamic>?;
                            final medName =
                                medication?['med_name'] as String? ?? 'Unknown';

                            Color statusColor = status == 'taken'
                                ? Colors.green
                                : status == 'missed'
                                    ? Colors.red
                                    : Colors.orange;
                            IconData statusIcon = status == 'taken'
                                ? Icons.check_circle
                                : status == 'missed'
                                    ? Icons.cancel
                                    : Icons.access_time;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                    color: statusColor.withOpacity(0.3)),
                              ),
                              elevation: 0,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: statusColor.withOpacity(0.1),
                                  child: Icon(statusIcon, color: statusColor),
                                ),
                                title: Text(medName,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  'Scheduled: ${log['scheduled_at']?.toString().substring(11, 16) ?? ''} • Status: ${status.toUpperCase()}',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                                trailing: status == 'pending'
                                    ? ElevatedButton(
                                        onPressed: () =>
                                            _markTaken(log['log_id'] as int),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                        ),
                                        child: Text('Taken',
                                            style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }
}
