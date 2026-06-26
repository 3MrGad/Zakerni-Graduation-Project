import 'package:flutter/material.dart';

class FeaturesScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const FeaturesScreen({
    super.key,
    this.onBack,
  });

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen> {
  final Map<String, _FeatureItem> features = {
    'memories': _FeatureItem(
      title: 'Memories',
      subtitle: 'Photo & memory gallery for patients',
      icon: Icons.photo_library_outlined,
      enabled: true,
    ),
    'medication': _FeatureItem(
      title: 'Medication',
      subtitle: 'Medication reminders and tracking',
      icon: Icons.medication_outlined,
      enabled: true,
    ),
    'mentalHealth': _FeatureItem(
      title: 'Mental Health',
      subtitle: 'Mood tracking and wellness tips',
      icon: Icons.favorite_outline,
      enabled: true,
    ),
    'voiceAssistant': _FeatureItem(
      title: 'Voice Assistant',
      subtitle: 'AI-powered voice interaction',
      icon: Icons.mic_none_outlined,
      enabled: false,
    ),
    'howToDo': _FeatureItem(
      title: 'How To Do',
      subtitle: 'Step-by-step daily activity guides',
      icon: Icons.menu_book_outlined,
      enabled: true,
    ),
  };

  int get enabledCount => features.values.where((f) => f.enabled).length;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF8B4F68);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE7EEF3),
        elevation: 0,
        automaticallyImplyLeading: true,
        title: const Text(
          "Manage Features",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onBack?.call();
          },
        ),
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B4F68), Color(0xFFB07090)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.toggle_on, color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Active Features",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      "$enabledCount / ${features.length} enabled",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Feature list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: features.entries.map((entry) {
                final key = entry.key;
                final item = entry.value;
                return _featureTile(
                  item: item,
                  onChanged: (value) {
                    setState(() {
                      features[key]!.enabled = value;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureTile({
    required _FeatureItem item,
    required ValueChanged<bool> onChanged,
  }) {
    const primaryColor = Color(0xFF8B4F68);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.enabled
                    ? const Color(0xFFF2BCD0).withOpacity(0.5)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: item.enabled ? primaryColor : Colors.grey,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: item.enabled ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          item.enabled ? Colors.black45 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: item.enabled,
              onChanged: onChanged,
              activeColor: primaryColor,
              activeTrackColor: const Color(0xFFF2BCD0),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String subtitle;
  final IconData icon;
  bool enabled;

  _FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
  });
}
