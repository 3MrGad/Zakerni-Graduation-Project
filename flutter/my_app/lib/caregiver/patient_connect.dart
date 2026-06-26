import 'package:flutter/material.dart';

class PatientConnect extends StatefulWidget {
  const PatientConnect({super.key});

  @override
  State<PatientConnect> createState() => _PatientConnectState();
}

class _PatientConnectState extends State<PatientConnect> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // AppBar محذوف
      // BottomNavigationBar محذوف
      body: SingleChildScrollView(
        child: Column(
          children: [
            // مكان الخريطة (فاضي)
            Container(
              height: 320,
              width: double.infinity,
              color: const Color(0xFFE0F2F1),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      "Live Tracking Map",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Current Location Card
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                40,
                16,
                8,
              ), // زيادة المسافة من الأعلى
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Current Location",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Safe Zone",
                          style: TextStyle(
                            color: Color(0xFF4A7C59),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "1224 Rosewood Avenue,\nGarden District",
                      style: TextStyle(fontSize: 15, height: 1.4),
                    ),
                    const Text(
                      "Updated 2m ago",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const Divider(height: 30),

                    // Speed & Battery
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFFE3F2FD),
                                child: Icon(
                                  Icons.directions_walk,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "SPEED",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    "0.4 mph",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFFF3E5F5),
                                child: Icon(
                                  Icons.battery_full,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "BATTERY",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    "82%",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Recent Movements
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Recent Movements",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            _movementItem(
              "Moved to Backyard",
              "Stayed for 15 minutes",
              "10:45 AM",
            ),
            _movementItem("Arrived at Home", "From: Senior Center", "10:30 AM"),
            _movementItem("Left Senior Center", "", "10:15 AM"),

            const SizedBox(height: 30),

            // Call Emergency Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "CALL EMERGENCY",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _movementItem(String title, String subtitle, String time) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 10, color: Color(0xFF4A7C59)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
