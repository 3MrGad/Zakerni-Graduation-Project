import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

// ══════════════════════════════════════════
// رابط الـ Worker
// ══════════════════════════════════════════
const String kWorkerUrl = 'https://patient-chat.wesayman123.workers.dev/';

// ══════════════════════════════════════════
// نظام الألوان الجديد - أنيق وحديث
// ══════════════════════════════════════════
class AppColors {
  // الألوان الأساسية - أزرق فيروزي مريح
  static const Color primary = Color(0xFF2D6A4F); // أخضر زمردي غامق
  static const Color primaryLight = Color(0xFF52B788); // أخضر فاتح
  static const Color primaryDark = Color(0xFF1B4332); // أخضر غامق جداً

  // ألوان ثانوية - دافئة ومريحة
  static const Color secondary = Color(0xFFE9C46A); // أصفر ذهبي ناعم
  static const Color accent = Color(0xFFF4A261); // برتقالي دافئ

  // خلفيات
  static const Color bg = Color(0xFFF8F9FA); // رمادي فاتح جداً
  static const Color card = Color(0xFFFFFFFF); // أبيض نقي
  static const Color surface = Color(0xFFF1F3F5); // رمادي خفيف

  // فقاعات الرسائل
  static const Color userBubble = Color(0xFF2D6A4F); // أخضر غامق
  static const Color botBubble = Color(0xFFFFFFFF); // أبيض
  static const Color supportBubble = Color(0xFFFFF3E0); // برتقالي فاتح جداً
  static const Color criticalBubble = Color(0xFFE63946); // أحمر للطوارئ

  // نصوص
  static const Color textPrimary = Color(0xFF212529); // أسود مائل للرمادي
  static const Color textSecondary = Color(0xFF6C757D); // رمادي متوسط
  static const Color textLight = Color(0xFFADB5BD); // رمادي فاتح

  // حالة
  static const Color safe = Color(0xFF2D6A4F);
  static const Color needsSupport = Color(0xFFE9C46A);
  static const Color critical = Color(0xFFE63946);

  // حدود
  static const Color border = Color(0xFFE9ECEF);
  static const Color divider = Color(0xFFDEE2E6);

  // تأثيرات
  static const Color shadow = Color(0x1A000000);
}

// ══════════════════════════════════════════
// نموذج الرسالة
// ══════════════════════════════════════════
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final String level;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.level,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

// ══════════════════════════════════════════
// الـ Widget الرئيسي
// ══════════════════════════════════════════
class ChatbotScreen extends StatefulWidget {
  final int patientId;
  final String patientName;
  final String caregiverName;
  final String homeDescription;
  final List<String> comfortItems;

  const ChatbotScreen({
    super.key,
    required this.patientId,
    this.patientName = 'صديقي',
    this.caregiverName = 'الشخص الموثوق',
    this.homeDescription = '',
    this.comfortItems = const [],
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;

  String _state = 'NONE';
  String _criticalState = 'NONE';
  int _criticalStep = 0;

  final List<Map<String, String>> _history = [];

  final SpeechToText _stt = SpeechToText();
  bool _sttAvailable = false;
  String _voiceText = '';

  final FlutterTts _tts = FlutterTts();
  bool _ttsEnabled = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _initVoice();
    _initTts();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _sendWelcome());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initVoice() async {
    _sttAvailable = await _stt.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
          if (_voiceText.isNotEmpty) {
            _sendMessage(_voiceText);
            _voiceText = '';
          }
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ar-EG');
    await _tts.setSpeechRate(0.8);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  Future<void> _sendWelcome() async {
    await _callWorker('');
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stt.stop();
      setState(() => _isListening = false);
      return;
    }

    final micStatus = await Permission.microphone.request();
    final speechStatus = await Permission.speech.request();
    if (micStatus.isDenied || speechStatus.isDenied) {
      _showSnack('محتاج إذن الميكروفون');
      return;
    }

    if (!_sttAvailable) {
      _sttAvailable = await _stt.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
            if (_voiceText.isNotEmpty) {
              _sendMessage(_voiceText);
              _voiceText = '';
            }
          }
        },
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (!_sttAvailable) {
        _showSnack('الميكروفون غير متاح');
        return;
      }
    }

    setState(() {
      _isListening = true;
      _voiceText = '';
    });
    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        setState(() => _voiceText = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _stt.stop();
        }
      },
      localeId: 'ar_EG',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<Map<String, double?>> _getLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return {'latitude': pos.latitude, 'longitude': pos.longitude};
    } catch (_) {
      return {'latitude': null, 'longitude': null};
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    _textController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        level: 'SAFE',
      ));
    });
    _scrollToBottom();
    await _callWorker(text);
  }

  String _removeEmojis(String text) {
    return text.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}'
        r'\u{1F300}-\u{1F5FF}'
        r'\u{1F680}-\u{1F6FF}'
        r'\u{1F700}-\u{1F77F}'
        r'\u{1F780}-\u{1F7FF}'
        r'\u{1F800}-\u{1F8FF}'
        r'\u{1F900}-\u{1F9FF}'
        r'\u{1FA00}-\u{1FA6F}'
        r'\u{1FA70}-\u{1FAFF}'
        r'\u{2600}-\u{26FF}'
        r'\u{2700}-\u{27BF}]',
        unicode: true,
      ),
      '',
    );
  }

  Future<void> _callWorker(String text) async {
    setState(() => _isLoading = true);

    bool needsLocation = _state.startsWith('ORIENT') ||
        text.contains('تايه') ||
        text.contains('فين');

    Map<String, double?> gps = {'latitude': null, 'longitude': null};
    bool sendLocationAlert = false;
    if (needsLocation) {
      gps = await _getLocation();
      sendLocationAlert = gps['latitude'] != null;
    }

    try {
      final body = {
        'patient_id': widget.patientId,
        'text': text,
        'patient_name': widget.patientName,
        'caregiver_name': widget.caregiverName,
        'home_description': widget.homeDescription,
        'comfort_items': widget.comfortItems,
        'history': _history,
        'state': _state,
        'critical_state': _criticalState,
        'critical_step': _criticalStep,
        if (gps['latitude'] != null) 'latitude': gps['latitude'],
        if (gps['longitude'] != null) 'longitude': gps['longitude'],
        if (sendLocationAlert) 'request_location_alert': true,
      };

      final response = await http
          .post(
            Uri.parse(kWorkerUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawReply = data['reply'] as String? ?? 'أنا هنا معاك.';
        final level = data['level'] as String? ?? 'SAFE';
        final newState = data['state'] as String? ?? 'NONE';
        final newCritical = data['critical_state'] as String? ?? 'NONE';
        final newStep = data['critical_step'] as int? ?? 0;
        final cleanReply = _removeEmojis(rawReply);

        _state = newState;
        _criticalState = newCritical;
        _criticalStep = newStep;

        if (text.isNotEmpty) _history.add({'role': 'user', 'text': text});
        _history.add({'role': 'assistant', 'text': cleanReply});
        if (_history.length > 24) _history.removeRange(0, 2);

        setState(() {
          _messages.add(ChatMessage(
            text: cleanReply,
            isUser: false,
            level: level,
          ));
        });

        if (_ttsEnabled) {
          await _tts.stop();
          await _tts.speak(cleanReply);
        }
        if (level == 'CRITICAL') _showCriticalDialog(cleanReply);
      } else {
        _addErrorMessage();
      }
    } catch (_) {
      _addErrorMessage();
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _addErrorMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: 'عندي مشكلة في الاتصال. جرب/ي تاني بعد شوية.',
        isUser: false,
        level: 'SAFE',
      ));
    });
  }

  void _showCriticalDialog(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.critical,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
            SizedBox(width: 8),
            Text(
              'تنبيه عاجل',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'حسناً',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _triggerEmergency() async {
    _showSnack('جاري إرسال موقعك...');
    final gps = await _getLocation();
    await _callWorkerDirect({
      'text': 'طوارئ — زرار الطوارئ',
      'request_location_alert': true,
      if (gps['latitude'] != null) 'latitude': gps['latitude'],
      if (gps['longitude'] != null) 'longitude': gps['longitude'],
    });
  }

  Future<void> _callWorkerDirect(Map<String, dynamic> extra) async {
    final body = {
      'patient_id': widget.patientId,
      'text': extra['text'] ?? '',
      'patient_name': widget.patientName,
      'caregiver_name': widget.caregiverName,
      'history': _history,
      'state': _state,
      'critical_state': _criticalState,
      'critical_step': _criticalStep,
      ...extra,
    };
    try {
      final response = await http
          .post(
            Uri.parse(kWorkerUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawReply = data['reply'] as String? ?? 'تم إرسال التنبيه.';
        final cleanReply = _removeEmojis(rawReply);
        setState(() {
          _messages.add(ChatMessage(
            text: cleanReply,
            isUser: false,
            level: 'CRITICAL',
          ));
        });
        if (_ttsEnabled) await _tts.speak(cleanReply);
        _scrollToBottom();
      }
    } catch (_) {
      _showSnack('فشل إرسال التنبيه. جرب تاني.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatusBar(),
          Expanded(child: _buildMessagesList()),
          if (_isListening) _buildListeningBar(),
          if (_voiceText.isNotEmpty) _buildVoicePreview(),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      title: Column(
        children: [
          const Text(
            'رفيق',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            'مساعدك الشخصي',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
            ),
          ),
        ],
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.favorite_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              _ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () {
              setState(() => _ttsEnabled = !_ttsEnabled);
              if (!_ttsEnabled) _tts.stop();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatusItem(
            'متصفح',
            Icons.check_circle_rounded,
            AppColors.safe,
          ),
          _buildStatusItem(
            'المساعد نشط',
            Icons.headset_mic_rounded,
            AppColors.primary,
          ),
          _buildStatusItem(
            widget.patientName,
            Icons.person_rounded,
            AppColors.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _messages.length) return _buildTypingIndicator();
        return _buildMessageBubble(_messages[i]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isUser) return _buildUserBubble(msg);

    switch (msg.level) {
      case 'CRITICAL':
        return _buildCriticalBubble(msg);
      case 'NEEDS_SUPPORT':
        return _buildSupportBubble(msg);
      default:
        return _buildBotBubble(msg);
    }
  }

  Widget _buildUserBubble(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'أنت',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: AppColors.userBubble,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotBubble(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'رفيق',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: AppColors.botBubble,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLevelBadge('آمن'),
                  const SizedBox(height: 6),
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      height: 1.4,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportBubble(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'رفيق',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 12,
                  backgroundColor:
                      AppColors.needsSupport.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 14,
                    color: AppColors.needsSupport,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: AppColors.supportBubble,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(
                  color: AppColors.needsSupport.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLevelBadge('يحتاج دعم'),
                  const SizedBox(height: 6),
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      height: 1.4,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalBubble(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تنبيه عاجل',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.critical,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.critical.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: AppColors.critical,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: AppColors.criticalBubble,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(String level) {
    Color bgColor;
    Color textColor;
    String icon;

    if (level == 'يحتاج دعم') {
      bgColor = AppColors.needsSupport.withValues(alpha: 0.2);
      textColor = AppColors.needsSupport;
      icon = '⚠️';
    } else {
      bgColor = AppColors.safe.withValues(alpha: 0.2);
      textColor = AppColors.safe;
      icon = '✓';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            level,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.botBubble,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 6),
            _buildDot(1),
            const SizedBox(width: 6),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final value = (index + 1) * 0.2;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.4 + (index + 1) * 0.2,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildListeningBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'جاري الاستماع...',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoicePreview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.record_voice_over_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _voiceText,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.send_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: () {
              if (_voiceText.isNotEmpty) {
                final text = _voiceText;
                setState(() => _voiceText = '');
                _sendMessage(text);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildActionButton(
              icon: Icons.emergency_rounded,
              color: AppColors.critical,
              onTap: _triggerEmergency,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: _textController,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك هنا...',
                    hintTextDirection: TextDirection.rtl,
                    hintStyle: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              icon: _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: _isListening ? AppColors.critical : AppColors.primary,
              onTap: _toggleListening,
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.send_rounded,
              color: AppColors.primary,
              onTap: () => _sendMessage(_textController.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }
}
