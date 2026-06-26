import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../game/game_api_service.dart';
import 'package:flutter/foundation.dart';

class CaregiverPeopleScreen extends StatefulWidget {
  const CaregiverPeopleScreen({super.key});

  @override
  State<CaregiverPeopleScreen> createState() => _CaregiverPeopleScreenState();
}

class _CaregiverPeopleScreenState extends State<CaregiverPeopleScreen> {
  List<Map<String, dynamic>> _people = [];
  List<String> _groupPhotos = [];
  bool _loading = true;
  bool _loadingGroup = true;

  // ✅ مضاف
  int? _patientId;
  String _patientName = '';

  @override
  void initState() {
    super.initState();
    _initFromSession(); // ✅ بدل _loadPeople و _loadGroupPhotos مباشرة
  }

  // ✅ مضاف
  Future<void> _initFromSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _patientId = prefs.getInt('caregiver_patient_id');
      _patientName = prefs.getString('patient_name') ?? '';
    });
    if (_patientId != null) {
      _loadPeople();
      _loadGroupPhotos();
    } else {
      setState(() {
        _loading = false;
        _loadingGroup = false;
      });
    }
  }

  // ─── Known People ──────────────────────────────────────────────────────────

  Future<void> _loadPeople() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('$kFlaskUrl/api/get_people/$_patientId'), // ✅
      );
      final data = jsonDecode(res.body);
      setState(() {
        _people = List<Map<String, dynamic>>.from(data['people'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addPerson() async {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    XFile? pickedImage;
    bool uploading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إضافة شخص جديد',
                style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D3561)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'اسم الشخص *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationCtrl,
                decoration: InputDecoration(
                  labelText: 'العلاقة (مثلاً: ابن، زوجة)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final img = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (img != null) setModal(() => pickedImage = img);
                },
                child: Container(
                  width: double.infinity,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F0E8),
                    border:
                        Border.all(color: const Color(0xFFE8D5B7), width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(pickedImage!.path,
                                  fit: BoxFit.cover)
                              : Image.file(File(pickedImage!.path),
                                  fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined,
                                size: 36, color: Color(0xFF6B9080)),
                            const SizedBox(height: 8),
                            Text(
                              'اضغط لاختيار صورة',
                              style: GoogleFonts.nunito(
                                  color: const Color(0xFF6B9080),
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B9080),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: uploading
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty ||
                              pickedImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('الاسم والصورة مطلوبين')),
                            );
                            return;
                          }
                          setModal(() => uploading = true);

                          final req = http.MultipartRequest(
                            'POST',
                            Uri.parse('$kFlaskUrl/api/add_person'),
                          );
                          req.fields['patient_id'] = _patientId.toString(); // ✅
                          req.fields['name'] = nameCtrl.text.trim();
                          req.fields['relation'] = relationCtrl.text.trim();
                          req.files.add(await http.MultipartFile.fromPath(
                              'photo', pickedImage!.path));

                          try {
                            final res = await req.send();
                            final body =
                                jsonDecode(await res.stream.bytesToString());
                            if (body['status'] == 'ok') {
                              if (mounted) Navigator.pop(ctx);
                              await Future.delayed(
                                  const Duration(milliseconds: 500));
                              _loadPeople();
                            } else {
                              setModal(() => uploading = false);
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text(body['error'] ?? 'حدث خطأ')),
                                );
                            }
                          } catch (e) {
                            setModal(() => uploading = false);
                          }
                        },
                  child: uploading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text('حفظ',
                          style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePerson(int personId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الشخص'),
        content: Text('هل تريد حذف "$name"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await http.delete(Uri.parse('$kFlaskUrl/api/delete_person/$personId'));
      _loadPeople();
    }
  }

  // ─── Group Photos ──────────────────────────────────────────────────────────

  Future<void> _loadGroupPhotos() async {
    setState(() => _loadingGroup = true);
    try {
      final res = await http.get(
        Uri.parse('$kFlaskUrl/api/get_group_photos/$_patientId'), // ✅
      );
      final data = jsonDecode(res.body);
      setState(() {
        _groupPhotos = List<String>.from(data['photos'] ?? []);
        _loadingGroup = false;
      });
    } catch (e) {
      setState(() => _loadingGroup = false);
    }
  }

  Future<void> _uploadGroupPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('جاري رفع ${images.length} صورة...')),
      );
    }

    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$kFlaskUrl/api/add_group_photo'),
    );
    req.fields['patient_id'] = _patientId.toString(); // ✅

    for (final img in images) {
      req.files.add(await http.MultipartFile.fromPath('photos', img.path));
    }

    try {
      final res = await req.send();
      final body = jsonDecode(await res.stream.bytesToString());
      if (body['status'] == 'ok') {
        _loadGroupPhotos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم رفع ${body['count']} صورة بنجاح ✓'),
              backgroundColor: const Color(0xFF6B9080),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body['error'] ?? 'حدث خطأ أثناء الرفع')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الاتصال بالسيرفر')),
        );
      }
    }
  }

  Future<void> _deleteGroupPhoto(String filename) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الصورة'),
        content: const Text('هل تريد حذف هذه الصورة من اللعبة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await http.delete(
        Uri.parse('$kFlaskUrl/api/delete_group_photo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': _patientId, // ✅
          'filename': filename,
        }),
      );
      _loadGroupPhotos();
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F0E8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أشخاص المريض',
              style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D3561)),
            ),
            Text(
              _patientName, // ✅ بدل widget.patientName
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPerson,
        backgroundColor: const Color(0xFF6B9080),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          'إضافة شخص',
          style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B9080)))
          : ListView(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 100),
              children: [
                _SectionHeader(
                  icon: Icons.people_outline,
                  title: 'الأشخاص المسجلون',
                  subtitle: 'صور وجوههم يتعلم منها النموذج',
                ),
                const SizedBox(height: 12),
                if (_people.isEmpty)
                  _EmptyHint(
                    emoji: '👥',
                    message: 'لم تتم إضافة أشخاص بعد',
                    hint: 'اضغط + لإضافة الأشخاص الذين يحتاج المريض لتذكرهم',
                  )
                else
                  ..._people.map((p) => _PersonTile(
                        person: p,
                        onDelete: () => _deletePerson(
                            p['person_id'] as int, p['name'] as String),
                      )),
                const SizedBox(height: 28),
                _SectionHeader(
                  icon: Icons.photo_library_outlined,
                  title: 'صور المجموعات',
                  subtitle: 'الصور اللي هتظهر في اللعبة',
                  action: TextButton.icon(
                    onPressed: _uploadGroupPhotos,
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        size: 18, color: Color(0xFF6B9080)),
                    label: Text(
                      'رفع صور',
                      style: GoogleFonts.nunito(
                          color: const Color(0xFF6B9080),
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'كل صورة لازم تحتوي على وجه واحد على الأقل من الأشخاص المسجلين فوق',
                  style:
                      GoogleFonts.nunito(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 12),
                if (_loadingGroup)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child:
                          CircularProgressIndicator(color: Color(0xFF6B9080)),
                    ),
                  )
                else if (_groupPhotos.isEmpty)
                  _EmptyHint(
                    emoji: '🖼️',
                    message: 'لا توجد صور مجموعات بعد',
                    hint: 'اضغط "رفع صور" لإضافة صور ستظهر في اللعبة',
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _groupPhotos.length,
                    itemBuilder: (_, i) => _GroupPhotoTile(
                      patientId: _patientId!, // ✅
                      filename: _groupPhotos[i],
                      onDelete: () => _deleteGroupPhoto(_groupPhotos[i]),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ─── Widgets مساعدة ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6B9080)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D3561)),
              ),
              Text(
                subtitle,
                style:
                    GoogleFonts.nunito(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String emoji;
  final String message;
  final String hint;

  const _EmptyHint({
    required this.emoji,
    required this.message,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.nunito(fontSize: 15, color: Colors.grey[500]),
            ),
            const SizedBox(height: 6),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final Map<String, dynamic> person;
  final VoidCallback onDelete;

  const _PersonTile({required this.person, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFA4C3B2),
            child: Text(
              (person['name'] as String).isNotEmpty
                  ? (person['name'] as String)[0]
                  : '?',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person['name'] as String,
                  style: GoogleFonts.nunito(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                if ((person['relation'] ?? '').isNotEmpty)
                  Text(
                    person['relation'] as String,
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: Colors.grey[500]),
                  ),
                Text(
                  '${person['photo_count']} صورة',
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: const Color(0xFF6B9080)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE07A5F)),
          ),
        ],
      ),
    );
  }
}

class _GroupPhotoTile extends StatelessWidget {
  final int patientId;
  final String filename;
  final VoidCallback onDelete;

  const _GroupPhotoTile({
    required this.patientId,
    required this.filename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final url = '$kFlaskUrl/static/patients/$patientId/group/$filename'
        '?t=${DateTime.now().millisecondsSinceEpoch}';

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFE8D5B7),
              child: const Icon(Icons.broken_image_outlined,
                  color: Color(0xFF6B9080)),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
