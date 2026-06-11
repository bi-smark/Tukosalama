import 'package:flutter/material.dart';
import 'package:tuko_salama/account_setup_page.dart';
import '../models/user_model.dart';
import '../admin/admin_dashboard.dart';
import '../security/security_dashboard.dart';
import '../student/student_dashboard.dart';
import 'package:tuko_salama/shared/suspended_user_page.dart';

class AppLayout extends StatelessWidget {
  final TukoUser user;

  const AppLayout({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // 1. Check for suspension first
    if (user.isSuspended) {
      return SuspendedUserPage(user: user);
    }

    // 2. Check for missing info (directed to setup page for injected users)
    if (user.username.isEmpty) {
      return AccountSetupPage(uid: user.uid);
    }

    // 3. Normal Dashboard Routing
    // FIX: Using UserRole Enum values instead of Strings
    switch (user.role) {
      case UserRole.admin:
        return AdminDashboard(user: user);
      case UserRole.security:
        return SecurityDashboard(user: user);
      case UserRole.student:
        return StudentDashboard(user: user);
    }
  }
}
