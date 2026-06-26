import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
//import 'package:cached_network_image/cached_network_image.dart';
import 'game_api_service.dart';
import 'game_models.dart';
import 'theme.dart';
import 'common_widgets.dart';
import 'result_screen.dart';
//import 'dashboard_screen.dart';

class GameScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  const GameScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  QuestionState? _q;
  bool _loading = true;
  bool _submitting = false;
  int _timeRemaining = 30;
  Timer? _timer;
  DateTime _questionStart = DateTime.now();
  String _localFeedback = '';
  String _localHint = '';
  String _imageKey = '';
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startGame() async {
    setState(() => _loading = true);
    try {
      await GameApiService.startGame(widget.patientId);
      await _loadQuestion();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadQuestion({bool clearFeedback = true}) async {
    setState(() {
      _loading = true;
      if (clearFeedback) {
        _localFeedback = '';
        _localHint = '';
        _showFeedback = false;
      }
    });
    try {
      final data = await GameApiService.getQuestion(widget.patientId);
      if (!mounted) return;
      final q = QuestionState.fromJson(data);
      setState(() {
        _q = q;
        _imageKey = '${q.imagePath}_${DateTime.now().millisecondsSinceEpoch}';
        _loading = false;
        _timeRemaining = q.timeLimit;
        _questionStart = DateTime.now();
      });
      _startTimer();
      if (q.levelMessage != null) _showLevelToast(q.levelMessage!);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _timeRemaining--);
      if (_timeRemaining <= 0) {
        t.cancel();
        _submitAnswer('__timeout__');
      }
    });
  }

  Future<void> _submitAnswer(String answer) async {
    if (_submitting) return;
    _timer?.cancel();
    setState(() => _submitting = true);

    final elapsed =
        DateTime.now().difference(_questionStart).inMilliseconds / 1000.0;

    try {
      final res = await GameApiService.submitAnswer(
        patientId: widget.patientId,
        answer: answer,
        responseTime: elapsed,
      );
      if (!mounted) return;

      final isCorrect = res['correct'] as bool? ?? false;
      final correctName = res['correct_name'] as String? ?? '';

      setState(() {
        _submitting = false;
        _localFeedback = isCorrect ? 'correct' : correctName;
        _showFeedback = true;
      });

      if (res['game_over'] == true) {
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              patientId: widget.patientId,
              patientName: widget.patientName,
            ),
          ),
        );
        return;
      }

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      _loadQuestion();
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _getHint() async {
    try {
      final res = await GameApiService.getHint(widget.patientId);
      if (!mounted) return;
      setState(() => _localHint = res['hint'] as String? ?? '');
    } catch (_) {}
  }

  void _showLevelToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
      backgroundColor: AppColors.navy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  Color _parseLevelColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🧠 حكايات ما بتتنسيش',
              style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy),
            ),
            Text(
              widget.patientName,
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              _timer?.cancel();
              await GameApiService.restartGame(widget.patientId);
              if (mounted) _startGame();
            },
            child: const Text('🔄', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.sage))
          : _q == null
              ? _buildError()
              : _buildGame(),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'لم يتم إضافة أشخاص بعد.\nاطلب من مقدم الرعاية إضافة أشخاص أولاً.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _startGame, child: const Text('إعادة المحاولة')),
          ]),
        ),
      );

  Widget _buildGame() {
    final q = _q!;
    final color = _parseLevelColor(q.levelColor);
    final badges = ['A', 'B', 'C', 'D'];
    final locked = _showFeedback || _submitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child:
                    GameProgressBar(current: q.questionNumber, total: q.total)),
            const SizedBox(width: 12),
            StatPill(value: '${q.score}', label: 'Score'),
          ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LevelBadge(label: q.levelLabel, color: color),
              TimerRing(remaining: _timeRemaining, total: q.timeLimit),
            ],
          ),
          const SizedBox(height: 14),
          if (_showFeedback) ...[
            FeedbackBanner(feedback: _localFeedback)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.1),
            const SizedBox(height: 12),
          ],
          if (_localHint.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEF),
                border: const Border(
                    left: BorderSide(color: AppColors.amber, width: 4)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '💡 تلميح: اسمهم يبدأ بـ "$_localHint"',
                style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: q.imagePath.isNotEmpty
                  ? Image.network(
                      '${GameApiService.imageUrl(q.imagePath)}?t=$_imageKey',
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              color: const Color(0xFFE8E4DE),
                              child: const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.sage)),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE8E4DE),
                        child: const Center(
                            child: Text('🖼️', style: TextStyle(fontSize: 48))),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFE8E4DE),
                      child: const Center(
                          child: Text('🖼️', style: TextStyle(fontSize: 48))),
                    ),
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Center(
              child: Text(
            'من هو؟',
            style: GoogleFonts.nunito(
                fontSize: 13,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic),
          )),
          const SizedBox(height: 20),
          Text(
            'من هذا؟',
            style: GoogleFonts.lora(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.navy),
          ),
          const SizedBox(height: 14),
          ...List.generate(q.options.length, (i) {
            final option = q.options[i];
            Color? btnColor;
            if (_showFeedback &&
                _localFeedback != 'correct' &&
                option == _localFeedback) {
              btnColor = AppColors.sage.withValues(alpha: 0.15);
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OptionButton(
                label: option,
                badge: i < 4 ? badges[i] : '?',
                onTap: locked ? () {} : () => _submitAnswer(option),
                locked: locked,
                highlight: btnColor,
              ).animate(delay: (i * 60).ms).fadeIn().slideX(begin: 0.08),
            );
          }),
          const SizedBox(height: 8),
          if (_localHint.isEmpty && !_showFeedback)
            OutlinedButton.icon(
              onPressed: _getHint,
              icon: const Text('💡'),
              label: Text(
                'مساعدة',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800, fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.sage,
                side: const BorderSide(color: AppColors.sage, width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
