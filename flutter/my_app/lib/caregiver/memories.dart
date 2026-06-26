import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';


class Memories extends StatefulWidget {
  const Memories({super.key});

  @override
  State<Memories> createState() => _MemoriesState();
}

class _MemoriesState extends State<Memories> {
  final picker = ImagePicker();

  List<Map<String, dynamic>> memories = [];

  bool _showAddForm = false;
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();
  File? _photo;
  List<String> _people = [];
  final _addPersonController = TextEditingController();
  int _selectedMood = -1;

  final List<Map<String, dynamic>> _moods = [
    {
      "label": "LOVED",
      "icon": Icons.favorite,
      "color": const Color(0xFFF7A8B8),
      "iconColor": const Color(0xFFB03060),
    },
    {
      "label": "CALM",
      "icon": Icons.sentiment_satisfied_alt,
      "color": const Color(0xFFDDEEDD),
      "iconColor": const Color(0xFF4A7C59),
    },
    {
      "label": "JOYFUL",
      "icon": Icons.star,
      "color": const Color(0xFFB2D8F0),
      "iconColor": const Color(0xFF2A7AB8),
    },
    {
      "label": "OTHER",
      "icon": Icons.more_horiz,
      "color": const Color(0xFFEEEEEE),
      "iconColor": const Color(0xFFAAAAAA),
    },
  ];

  void deleteMemory(int index) {
    setState(() => memories.removeAt(index));
  }

  Future pickImage(int index) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => memories[index]["image"] = File(picked.path));
    }
  }

  Future _pickFormPhoto() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dateController.text =
            "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _removePerson(int index) => setState(() => _people.removeAt(index));

  void _resetForm() {
    descriptionController.clear();
    dateController.clear();
    _photo = null;
    _people = [];
    _selectedMood = -1;
    _showAddForm = false;
  }

  Future<void> _saveMemory() async {
    if (descriptionController.text.trim().isEmpty) return;

    try {
      await ApiService.addMemory(
        description: descriptionController.text.trim(),
        title: descriptionController.text.trim().length > 40
            ? '${descriptionController.text.trim().substring(0, 40)}...'
            : descriptionController.text.trim(),
        photoPath: _photo?.path,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }

    final now = DateTime.now();
    final months = [
      "JANUARY",
      "FEBRUARY",
      "MARCH",
      "APRIL",
      "MAY",
      "JUNE",
      "JULY",
      "AUGUST",
      "SEPTEMBER",
      "OCTOBER",
      "NOVEMBER",
      "DECEMBER",
    ];
    final dateLabel = dateController.text.isNotEmpty
        ? dateController.text
        : "${months[now.month - 1]} ${now.day}, ${now.year}";

    setState(() {
      memories.insert(0, {
        "date": dateLabel,
        "text": descriptionController.text.trim(),
        "people": _people.isEmpty ? "Me" : _people.join(", "),
        "image": _photo,
        "mood": _selectedMood,
      });
      _resetForm();
    });
  }

  Widget _labelAbove(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _personChip(String name, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 13, color: Color(0xFF2D2D2D)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removePerson(index),
            child: const Icon(Icons.close, size: 14, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  Widget _memoryCard(Map<String, dynamic> memory, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                memory["date"],
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFF5BA08A),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Color(0xFFE57373),
                ),
                onPressed: () => deleteMemory(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (memory["image"] != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                memory["image"],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            memory["text"],
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF2D2D2D),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 15,
                color: Color(0xFFE57373),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  memory["people"],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addMemoryBox() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF7A8B8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Capture a moment",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7A3060),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showAddForm = false),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFF888888),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Preserve a spark of joy or a meaningful interaction.",
            style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 20),

          _labelAbove(
            "MEMORY DESCRIPTION",
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: TextField(
                controller: descriptionController,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D2D)),
                decoration: const InputDecoration(
                  hintText: "What happened today that made you smile?",
                  hintStyle: TextStyle(color: Color(0xFF9EC5D0), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
          ),

          _labelAbove(
            "DATE OF MEMORY",
            TextField(
              controller: dateController,
              readOnly: true,
              onTap: _selectDate,
              style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D2D)),
              decoration: InputDecoration(
                hintText: "Pick a date",
                hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFADD8E6)),
                ),
                suffixIcon: const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF888888),
                  size: 18,
                ),
              ),
            ),
          ),

          _labelAbove(
            "PEOPLE INVOLVED",
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._people.asMap().entries.map(
                  (e) => _personChip(e.value, e.key),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text("Add Someone"),
                        content: TextField(
                          controller: _addPersonController,
                          decoration: const InputDecoration(
                            hintText: "Enter name",
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A7C59),
                            ),
                            onPressed: () {
                              if (_addPersonController.text.trim().isNotEmpty) {
                                setState(
                                  () => _people.add(
                                    _addPersonController.text.trim(),
                                  ),
                                );
                                _addPersonController.clear();
                              }
                              Navigator.pop(context);
                            },
                            child: const Text("Add"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_add_outlined,
                          size: 14,
                          color: Color(0xFF555555),
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Add Someone",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          _labelAbove(
            "HOW DID THIS FEEL?",
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_moods.length, (i) {
                final m = _moods[i];
                final sel = _selectedMood == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = i),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel
                              ? (m["color"] as Color)
                              : (m["color"] as Color).withOpacity(0.5),
                          border: sel
                              ? Border.all(
                                  color: m["iconColor"] as Color,
                                  width: 2.5,
                                )
                              : null,
                        ),
                        child: Icon(
                          m["icon"] as IconData,
                          color: m["iconColor"] as Color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        m["label"] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: sel
                              ? (m["iconColor"] as Color)
                              : const Color(0xFFAAAAAA),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          _labelAbove(
            "ADD A PHOTO",
            GestureDetector(
              onTap: _pickFormPhoto,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                ),
                child: _photo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(_photo!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: Color(0xFF888888),
                            size: 26,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Add a Photo",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF555555),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "Max file size 5MB",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7A8B8),
                foregroundColor: const Color(0xFF2D2D2D),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text(
                "Save to Memories",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              onPressed: _saveMemory,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),

      // AppBar محذوف
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          40,
          16,
          100,
        ), // زيادة بسيطة في الـ top padding لأن AppBar راح
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2EC),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A7C59),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Memory Bank",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Preserve the precious moments that\nbring joy to your caregiving journey.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => setState(() => _showAddForm = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 28,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7A8B8),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        "Add Real Memories That\nHappened With Patient",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D2D2D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_showAddForm) _addMemoryBox(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Memories",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB2EBD8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Total: ${memories.length}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D6A4F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (memories.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: const Column(
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      size: 48,
                      color: Color(0xFFCCCCCC),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "No memories yet.\nStart adding your first one!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
                    ),
                  ],
                ),
              )
            else
              ...memories
                  .asMap()
                  .entries
                  .map((e) => _memoryCard(e.value, e.key))
                  ,

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                border: Border.all(color: const Color(0xFFCCCCCC)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF888888),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Tip: Record even the smallest smiles. They build a beautiful legacy over time.",
                      style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF7A8B8),
        onPressed: () => setState(() => _showAddForm = !_showAddForm),
        child: Icon(
          _showAddForm ? Icons.close : Icons.add_photo_alternate_outlined,
          color: Colors.white,
        ),
      ),
    );
  }
}
