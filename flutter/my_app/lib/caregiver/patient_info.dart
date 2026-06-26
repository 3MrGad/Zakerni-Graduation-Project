import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class PatientAppColors {
  static const primary = Color.fromRGBO(255, 220, 230, 1);
  static const accent = Color.fromARGB(255, 0, 150, 136);
}

class PatientInfo extends StatefulWidget {
  const PatientInfo({super.key});

  @override
  State<PatientInfo> createState() => _PatientInfoState();
}

class _PatientInfoState extends State<PatientInfo> {
  final nameController = TextEditingController();
  final birthdayController = TextEditingController();
  final medicalController = TextEditingController();
  final chronicController = TextEditingController();
  final emergency1Controller = TextEditingController();
  final emergency2Controller = TextEditingController();
  final aboutController = TextEditingController();
  final likesController = TextEditingController();
  final dislikesController = TextEditingController();

  List<Map<String, dynamic>> relatives = [];
  final picker = ImagePicker();
  int? _patientId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final res = await ApiService.getPatientInfo();
      final data = res['data'] as Map<String, dynamic>?;
      final patient = data?['patient'] as Map<String, dynamic>? ?? data;
      if (patient != null) {
        setState(() {
          _patientId = patient['patient_id'] as int?;
          nameController.text = patient['name']?.toString() ?? '';
          medicalController.text = patient['medical_condition']?.toString() ?? '';
          chronicController.text = patient['chronic_diseases']?.toString() ?? '';
          emergency1Controller.text = patient['emergency_contact']?.toString() ?? '';
          emergency2Controller.text = patient['emergency_contact_2']?.toString() ?? '';
          aboutController.text = patient['about']?.toString() ?? '';
          likesController.text = patient['likes']?.toString() ?? '';
          dislikesController.text = patient['dislikes']?.toString() ?? '';
        });
      }
    } catch (_) {}
  }

  bool nameError = false;
  bool birthdayError = false;
  bool medicalError = false;
  bool chronicError = false;
  bool emergency1Error = false;

  Future pickImage(int index) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        relatives[index]["image"] = File(picked.path);
      });
    }
  }

  void addRelative() {
    setState(() {
      relatives.add({
        "name": TextEditingController(),
        "phone": TextEditingController(),
        "image": null,
      });
    });
  }

  void deleteRelative(int index) {
    setState(() {
      relatives.removeAt(index);
    });
  }

  Future selectBirthday() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        birthdayController.text =
            "${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.year}";
      });
    }
  }

  void validateFields() {
    setState(() {
      nameError = nameController.text.isEmpty;
      birthdayError = birthdayController.text.isEmpty;
      medicalError = medicalController.text.isEmpty;
      chronicError = chronicController.text.isEmpty;
      emergency1Error = emergency1Controller.text.isEmpty;
    });
  }

  Widget _labeledField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    String? hint,
    bool errorFlag = false,
  }) {
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
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D2D)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF0F6FF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: errorFlag ? Colors.red : Colors.transparent,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFADD8E6),
                width: 1.5,
              ),
            ),
            suffixIcon: readOnly
                ? const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Color(0xFF888888),
                  )
                : null,
          ),
        ),
        if (errorFlag) ...[
          const SizedBox(height: 4),
          const Text(
            "This field is required",
            style: TextStyle(color: Colors.red, fontSize: 11),
          ),
        ],
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(
    String title,
    IconData icon, {
    Color iconColor = const Color(0xFFB03060),
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _contactTile({
    required String initials,
    required String name,
    required String sub,
    required VoidCallback onDelete,
    ImageProvider? image,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFD0E8FF),
            backgroundImage: image,
            child: image == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF4A90D9),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFFB03060),
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0FB),
      // تم حذف الـ AppBar بالكامل
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: const [
                  Text(
                    "Patient Information",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Keep clinical and personal details up to date\nfor the best care.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  children: [
                    if (_patientId != null)
                      _sectionCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                readOnly: true,
                                controller: TextEditingController(text: '$_patientId'),
                                decoration: const InputDecoration(
                                  labelText: 'PATIENT ID',
                                  filled: true,
                                  fillColor: Color(0xFFE8F0FB),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: '$_patientId'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Patient ID copied')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            "Basic Information",
                            Icons.person_outline,
                            iconColor: const Color(0xFF888888),
                          ),
                          const SizedBox(height: 16),
                          _labeledField(
                            "FULL NAME",
                            nameController,
                            hint: "Eleanor Rigby",
                            errorFlag: nameError,
                          ),
                          _labeledField(
                            "DATE OF BIRTH",
                            birthdayController,
                            readOnly: true,
                            onTap: selectBirthday,
                            hint: "MM/DD/YYYY",
                            errorFlag: birthdayError,
                          ),
                        ],
                      ),
                    ),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            "Medical History",
                            Icons.medical_information_outlined,
                            iconColor: const Color(0xFFB03060),
                          ),
                          const SizedBox(height: 16),
                          _labeledField(
                            "DIAGNOSIS & NOTES",
                            medicalController,
                            maxLines: 4,
                            hint:
                                "Early-stage Alzheimer's diagnosed in 2022...",
                            errorFlag: medicalError,
                          ),
                          _labeledField(
                            "CHRONIC DISEASES",
                            chronicController,
                            hint: "e.g. Type 2 Diabetes, Arthritis",
                            errorFlag: chronicError,
                          ),
                        ],
                      ),
                    ),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            "Hobbies & Lifestyle",
                            Icons.favorite_border,
                            iconColor: const Color(0xFFB03060),
                          ),
                          const SizedBox(height: 16),
                          _labeledField(
                            "LIKES & HOBBIES",
                            likesController,
                            hint: "e.g. Classical music, gardening...",
                          ),
                          _labeledField(
                            "DISLIKES / TRIGGERS",
                            dislikesController,
                            hint: "e.g. Loud sudden noises, crowded...",
                          ),
                        ],
                      ),
                    ),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            "Emergency Contacts",
                            Icons.emergency_outlined,
                            iconColor: const Color(0xFFB03060),
                            trailing: GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFB03060),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          if (emergency1Controller.text.isNotEmpty)
                            _contactTile(
                              initials: "JD",
                              name: emergency1Controller.text,
                              sub: "(555) 123–4567",
                              onDelete: () =>
                                  setState(() => emergency1Controller.clear()),
                            ),
                          const SizedBox(height: 12),
                          _labeledField(
                            "EMERGENCY CONTACT 1",
                            emergency1Controller,
                            hint: "Name or phone number",
                            errorFlag: emergency1Error,
                          ),
                          _labeledField(
                            "EMERGENCY CONTACT 2",
                            emergency2Controller,
                            hint: "Name or phone number",
                          ),
                        ],
                      ),
                    ),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            "Relatives",
                            Icons.people_outline,
                            iconColor: const Color(0xFF888888),
                            trailing: GestureDetector(
                              onTap: addRelative,
                              child: const Icon(
                                Icons.person_add_outlined,
                                color: Color(0xFF888888),
                                size: 22,
                              ),
                            ),
                          ),
                          ...List.generate(relatives.length, (index) {
                            final rel = relatives[index];
                            final nameText =
                                (rel["name"] as TextEditingController).text;
                            final phoneText =
                                (rel["phone"] as TextEditingController).text;
                            return Column(
                              children: [
                                _contactTile(
                                  initials: nameText.isNotEmpty
                                      ? nameText[0].toUpperCase()
                                      : "?",
                                  name: nameText.isEmpty
                                      ? "Relative"
                                      : nameText,
                                  sub: phoneText.isEmpty
                                      ? "Son • Primary Contact"
                                      : phoneText,
                                  onDelete: () => deleteRelative(index),
                                  image: rel["image"] != null
                                      ? FileImage(rel["image"])
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                _labeledField(
                                  "NAME",
                                  rel["name"] as TextEditingController,
                                ),
                                _labeledField(
                                  "PHONE",
                                  rel["phone"] as TextEditingController,
                                ),
                                TextButton.icon(
                                  onPressed: () => pickImage(index),
                                  icon: const Icon(
                                    Icons.image_outlined,
                                    size: 16,
                                  ),
                                  label: const Text("Pick photo"),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // أبقينا فقط على زر الحفظ ليكون ثابتاً في الأسفل بدون شريط التنقل
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF7A8B8),
              foregroundColor: const Color(0xFF2D2D2D),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.save_outlined, size: 20),
            label: const Text(
              "Save Information",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: _saving
                ? null
                : () async {
                    validateFields();
                    if (nameError || birthdayError || medicalError || chronicError || emergency1Error) return;
                    setState(() => _saving = true);
                    try {
                      final res = await ApiService.savePatientInfo({
                        'name': nameController.text.trim(),
                        'medical_condition': medicalController.text.trim(),
                        'chronic_diseases': chronicController.text.trim(),
                        'emergency_contact': emergency1Controller.text.trim(),
                        'emergency_contact_2': emergency2Controller.text.trim(),
                        'about': aboutController.text.trim(),
                        'likes': likesController.text.trim(),
                        'dislikes': dislikesController.text.trim(),
                      });
                      final pid = res['data']?['patient_id'] ?? res['data']?['patient']?['patient_id'];
                      if (pid != null) setState(() => _patientId = pid as int);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Patient information saved')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                      );
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
          ),
        ),
      ),
    );
  }
}
