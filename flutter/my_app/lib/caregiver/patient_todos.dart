import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

/// Caregiver creates tasks; patient marks them complete in their app.
class PatientTodosScreen extends StatefulWidget {
  const PatientTodosScreen({super.key});

  @override
  State<PatientTodosScreen> createState() => _PatientTodosScreenState();
}

class _PatientTodosScreenState extends State<PatientTodosScreen> {
  List<dynamic> _patients = [];
  List<dynamic> _todos = [];
  dynamic _selectedPatient;
  bool _loading = true;
  bool _loadingTodos = false;
  bool _adding = false;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkPatientCtrl = TextEditingController();
  String _priority = 'medium';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _linkPatientCtrl.dispose();
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
        await _loadTodos();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTodos() async {
    if (_patientId == null) return;
    setState(() => _loadingTodos = true);
    try {
      final todos = await ApiService.getTodos(patientId: _patientId);
      setState(() => _todos = todos);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loadingTodos = false);
    }
  }

  Future<void> _linkPatient() async {
    final id = int.tryParse(_linkPatientCtrl.text.trim());
    if (id == null) {
      _showError('Enter a valid patient ID number');
      return;
    }
    try {
      await ApiService.linkPatient(id);
      _linkPatientCtrl.clear();
      Navigator.pop(context);
      await _bootstrap();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _addTodo() async {
    if (_patientId == null || _titleCtrl.text.trim().isEmpty) return;
    setState(() => _adding = true);
    try {
      await ApiService.addTodo(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        priority: _priority,
        patientId: _patientId,
      );
      _titleCtrl.clear();
      _descCtrl.clear();
      _priority = 'medium';
      if (mounted) Navigator.pop(context);
      await _loadTodos();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _adding = false);
    }
  }

  Future<void> _deleteTodo(int id) async {
    try {
      await ApiService.deleteTodo(id, patientId: _patientId);
      await _loadTodos();
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

  void _showLinkDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Link Patient'),
        content: TextField(
          controller: _linkPatientCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Patient ID', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: _linkPatient, child: const Text('Link')),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: StatefulBuilder(
          builder: (ctx, setModal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Task for Patient', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Task title *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Description', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: ['low', 'medium', 'high'].map((p) {
                  final selected = _priority == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(p),
                        selected: selected,
                        onSelected: (_) => setModal(() => _priority = p),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _adding ? null : _addTodo,
                  child: _adding ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Save Task'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Patient Tasks', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF5C4A8A))),
        iconTheme: const IconThemeData(color: Color(0xFF5C4A8A)),
      ),
      floatingActionButton: _patients.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: const Color(0xFF5C4A8A),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Link a patient first'),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _showLinkDialog, child: const Text('Link Patient')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_patients.length > 1)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButton<dynamic>(
                          isExpanded: true,
                          value: _selectedPatient,
                          items: _patients
                              .map((p) => DropdownMenuItem(value: p, child: Text(p['name'] as String? ?? 'Patient')))
                              .toList(),
                          onChanged: (p) async {
                            setState(() => _selectedPatient = p);
                            if (_patientId != null) await ApiService.setSelectedPatientId(_patientId!);
                            await _loadTodos();
                          },
                        ),
                      ),
                    Expanded(
                      child: _loadingTodos
                          ? const Center(child: CircularProgressIndicator())
                          : _todos.isEmpty
                              ? Center(child: Text('No tasks yet', style: GoogleFonts.inter(color: Colors.grey)))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _todos.length,
                                  itemBuilder: (ctx, i) {
                                    final todo = _todos[i] as Map<String, dynamic>;
                                    final done = todo['is_completed'] as bool;
                                    return Dismissible(
                                      key: Key('cg_todo_${todo['todo_id']}'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        color: Colors.red,
                                        child: const Icon(Icons.delete, color: Colors.white),
                                      ),
                                      onDismissed: (_) => _deleteTodo(todo['todo_id'] as int),
                                      child: Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? Colors.green : Colors.orange),
                                          title: Text(todo['title'] as String, style: TextStyle(decoration: done ? TextDecoration.lineThrough : null)),
                                          subtitle: Text(
                                            '${todo['created_by'] == 'patient' ? 'Patient' : 'Caregiver'} · ${done ? 'Done' : 'Pending'}',
                                          ),
                                        ),
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
