import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';// ── App Bar ───────────────────────────────────────────────────────────────────

class MemoryBridgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? username;
  final List<Widget>? actions;

  const MemoryBridgeAppBar({super.key, this.username, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 2,
      shadowColor: AppColors.shadow,
      title: Row(
        children: [
          const Text('🧠 ذاكرة', style: TextStyle(fontSize: 20)),
          Text('Bridge',
            style: GoogleFonts.lora(
              fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.sage,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}

// ── Stat Pill ─────────────────────────────────────────────────────────────────

class StatPill extends StatelessWidget {
  final String value;
  final String label;

  const StatPill({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
            style: GoogleFonts.nunito(
              fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
            style: GoogleFonts.nunito(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.grey[500], letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Bar ──────────────────────────────────────────────────────────────

class GameProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const GameProgressBar({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (current - 1) / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Question $current of $total',
              style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[500]),
            ),
            Text('${(pct * 100).toInt()}% done',
              style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: AppColors.warm,
            valueColor: const AlwaysStoppedAnimation(AppColors.sage),
          ),
        ),
      ],
    );
  }
}

// ── Timer Ring ────────────────────────────────────────────────────────────────

class TimerRing extends StatelessWidget {
  final int remaining;
  final int total;

  const TimerRing({super.key, required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? remaining / total : 1.0;
    final Color ringColor = ratio < 0.33
        ? AppColors.coral
        : ratio < 0.6
            ? AppColors.amber
            : AppColors.sage;

    return SizedBox(
      width: 64, height: 64,
      child: Stack(
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: ratio,
              strokeWidth: 5,
              backgroundColor: AppColors.warm,
              valueColor: AlwaysStoppedAnimation(ringColor),
            ),
          ),
          Center(
            child: Text(
              remaining > 0 ? '$remaining' : '⏰',
              style: GoogleFonts.nunito(
                fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Level Badge ───────────────────────────────────────────────────────────────

class LevelBadge extends StatelessWidget {
  final String label;
  final Color  color;

  const LevelBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(label,
        style: GoogleFonts.nunito(
          fontSize: 13, fontWeight: FontWeight.w800, color: color,
        ),
      ),
    );
  }
}

// ── Option Button ─────────────────────────────────────────────────────────────

class OptionButton extends StatelessWidget {
  final String     label;
  final String     badge;
  final VoidCallback onTap;
  final bool       locked;
  final Color?     highlight;

  const OptionButton({
    super.key,
    required this.label,
    required this.badge,
    required this.onTap,
    this.locked    = false,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor     = highlight ?? AppColors.white;
    final borderColor = highlight != null ? AppColors.sage : AppColors.warm;
    final opacity     = locked && highlight == null ? 0.6 : 1.0;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: locked ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 2.5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(badge,
                    style: GoogleFonts.nunito(
                      fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.navy,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                  style: GoogleFonts.nunito(
                    fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feedback Banner ───────────────────────────────────────────────────────────

class FeedbackBanner extends StatelessWidget {
  final String feedback;

  const FeedbackBanner({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    final isCorrect = feedback == 'correct';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFD4EDDA) : const Color(0xFFFDE8E4),
        border: Border(left: BorderSide(
          color: isCorrect ? const Color(0xFF28A745) : AppColors.coral,
          width: 5,
        )),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(isCorrect ? '✅' : '❌', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCorrect
                  ? 'تذكّر رائع! 🧠'
                  : 'كانت "$feedback" — لا بأس، جرّب ثانية!',
              style: GoogleFonts.nunito(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: isCorrect ? const Color(0xFF155724) : const Color(0xFF842029),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Person Row (for stats lists) ──────────────────────────────────────────────

class PersonRow extends StatelessWidget {
  final String name;
  final String stat;
  final Color  statColor;
  final String? subStat;

  const PersonRow({
    super.key,
    required this.name,
    required this.stat,
    required this.statColor,
    this.subStat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
  child: Text(
    name,
    overflow: TextOverflow.ellipsis,
    style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700),
  ),
),
          Row(
            children: [
              Text(stat,
                style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w900, color: statColor,
                ),
              ),
              if (subStat != null) ...[
                const SizedBox(width: 4),
                Text(subStat!,
                  style: GoogleFonts.nunito(
                    fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[400],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
