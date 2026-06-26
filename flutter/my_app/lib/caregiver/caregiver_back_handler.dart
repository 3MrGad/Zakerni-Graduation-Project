import 'package:flutter/material.dart';
import 'caregiver_home.dart';

/// Wraps caregiver sub-routes so system back returns to caregiver home tab, not login.
class CaregiverBackHandler extends StatelessWidget {
  final Widget child;
  final String userName;

  const CaregiverBackHandler({super.key, required this.child, this.userName = 'Caregiver'});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => CaregiverHome(userName: userName)),
          (_) => false,
        );
      },
      child: child,
    );
  }
}
