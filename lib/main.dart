import 'package:flutter/material.dart';
import 'screens/farmer_dashboard_screen.dart';
import 'screens/officer_dashboard_screen.dart';
import 'screens/role_selection_screen.dart';
import 'services/auth_service.dart';
import 'services/procurement_state_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Supabase client if configured (skipped gracefully in local mode)
  await SupabaseService.instance.initialize();

  // Check and restore existing session before deciding between Login or Dashboard
  final sessionState = await AuthService.instance.restoreSession();
  if (sessionState.isAuthenticated) {
    // If authenticated in Supabase mode, prime state from repositories
    await ProcurementStateService().loadFromRepositories();
  }

  runApp(KisanSetuApp(initialSession: sessionState));
}

/// Root widget for the KisanSetu application.
class KisanSetuApp extends StatelessWidget {
  final AuthSessionState? initialSession;

  const KisanSetuApp({
    super.key,
    this.initialSession,
  });

  Widget _resolveHomeScreen() {
    final session = initialSession;
    if (session != null && session.isAuthenticated) {
      if (session.role == UserRole.officer) {
        return OfficerDashboardScreen(
          officerId: session.officerId ?? 'OFFICER001',
        );
      } else if (session.role == UserRole.farmer) {
        return FarmerDashboardScreen(
          phoneNumber: session.phone ?? '9876543210',
          selectedLanguage: 'hi',
        );
      }
    }
    return const RoleSelectionScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KisanSetu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _resolveHomeScreen(),
    );
  }
}
