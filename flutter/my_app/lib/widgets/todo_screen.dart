import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<dynamic> _todos = [];
  bool _loading = true;
  bool _adding = false;
  bool _isPatient = true;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';

  @override
  void initState() {
    super.initState();
    _initRole();
  }

  Future<void> _initRole() async {
    final role = await ApiService.getRole();
    setState(() => _isPatient = role == 'patient');
    await _loadTodos();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    setState(() => _loading = true);
    try {
      if (_isPatient) {
        final tasks = await ApiService.getPatientTasks();
        setState(() => _todos = tasks);
      } else {
        final todos = await ApiService.getTodos();
        setState(() => _todos = todos);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleTodo(Map todo) async {
    try {
      if (_isPatient) {
        final id = (todo['id'] ?? todo['todo_id']) as int;
        final done = (todo['is_done'] ?? todo['is_completed']) as bool;
        if (!done) {
          await ApiService.markPatientTaskDone(id);
          await _loadTodos();
        }
        return;
      }
      final id = todo['todo_id'] as int;
      final done = todo['is_completed'] as bool;
      done
          ? await ApiService.uncompleteTodo(id)
          : await ApiService.completeTodo(id);
      await _loadTodos();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _deleteTodo(int id) async {
    try {
      await ApiService.deleteTodo(id);
      await _loadTodos();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _addTodo() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _adding = true);
    try {
      if (_isPatient) {
        await ApiService.addPatientTodo(
          title: _titleCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        );
      } else {
        await ApiService.addTodo(
          title: _titleCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          priority: _priority,
        );
      }
      _titleCtrl.clear();
      _descCtrl.clear();
      setState(() => _priority = 'medium');
      Navigator.pop(context);
      await _loadTodos();
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
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add New Task',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color.fromARGB(255, 0, 155, 239))),
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                decoration: _inputDeco('Task title *'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: _inputDeco('Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Text('Priority',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Row(
                children: ['low', 'medium', 'high'].map((p) {
                  final selected = _priority == p;
                  final color = p == 'high'
                      ? Colors.red
                      : p == 'medium'
                          ? const Color.fromARGB(255, 41, 103, 189)
                          : Colors.green;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setModalState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? color : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            p.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: selected ? Colors.white : color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _adding ? null : _addTodo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 56, 74, 212),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _adding
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Text('Add Task',
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
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color.fromARGB(255, 0, 187, 255), width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Color _priorityColor(String? p) {
    if (p == 'high') return Colors.red;
    if (p == 'low') return Colors.green;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    bool isDone(Map t) => (t['is_done'] ?? t['is_completed']) as bool;
    final pending = _todos.where((t) => !isDone(t)).length;
    final completed = _todos.where((t) => isDone(t)).length;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('TO DO LIST',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: const Color.fromARGB(255, 0, 167, 239))),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: const Color.fromARGB(255, 0, 119, 239)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTodos),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color.fromARGB(255, 0, 217, 255),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 0, 195, 255)))
          : Column(
              children: [
                // Summary bar
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      _statChip('$pending Pending',
                          const Color.fromARGB(255, 0, 238, 255)),
                      const SizedBox(width: 12),
                      _statChip('$completed Done', Colors.green),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: _todos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.checklist_rounded,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No tasks yet!',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey, fontSize: 18)),
                              Text(
                                _isPatient
                                    ? 'Your caregiver will assign tasks for you'
                                    : 'Tap + to add your first task',
                                style:
                                    GoogleFonts.inter(color: Colors.grey[400]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTodos,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _todos.length,
                            itemBuilder: (ctx, i) {
                              final todo = _todos[i] as Map<String, dynamic>;
                              final done = (todo['is_done'] ??
                                  todo['is_completed']) as bool;
                              final priority =
                                  todo['priority'] as String? ?? 'medium';
                              final createdBy =
                                  todo['created_by'] as String? ?? 'patient';

                              final card = Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                      color: done
                                          ? Colors.green.withOpacity(0.3)
                                          : _priorityColor(priority)
                                              .withOpacity(0.3)),
                                ),
                                elevation: 0,
                                child: CheckboxListTile(
                                  value: done,
                                  onChanged: (_) => _toggleTodo(todo),
                                  activeColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  title: Text(
                                    todo['title'] as String,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      decoration: done
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color:
                                          done ? Colors.grey : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if ((todo['description'] as String?) !=
                                              null &&
                                          (todo['description'] as String)
                                              .isNotEmpty)
                                        Text(todo['description'] as String,
                                            style: GoogleFonts.inter(
                                                color: Colors.grey[600],
                                                fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (!_isPatient ||
                                              createdBy == 'caregiver')
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  right: 6),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.teal
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                createdBy == 'caregiver'
                                                    ? 'From caregiver'
                                                    : priority.toUpperCase(),
                                                style: GoogleFonts.inter(
                                                    color: Colors.teal[800],
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                            ),
                                          if (_isPatient &&
                                              createdBy != 'caregiver')
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _priorityColor(priority)
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                priority.toUpperCase(),
                                                style: GoogleFonts.inter(
                                                    color: _priorityColor(
                                                        priority),
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              if (_isPatient) return card;
                              return Dismissible(
                                key: Key(todo['todo_id'].toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                onDismissed: (_) =>
                                    _deleteTodo(todo['todo_id'] as int),
                                child: card,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.inter(
              color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
