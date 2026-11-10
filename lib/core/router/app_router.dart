import 'package:go_router/go_router.dart';

import '../../features/admin/admin_shell.dart';
import '../../features/admin/beneficiaries_screen.dart';
import '../../features/admin/beneficiary_profile_screen.dart';
import '../../features/admin/dashboard_screen.dart';
import '../../features/admin/materials_screen.dart';
import '../../features/admin/print_cards_screen.dart';
import '../../features/admin/register_beneficiary_screen.dart';
import '../../features/admin/reports_screen.dart';
import '../../features/admin/rewards_screen.dart';
import '../../features/admin/schools_screen.dart';
import '../../features/admin/users_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/collector/beneficiary_card_screen.dart';
import '../../features/collector/collector_shell.dart';
import '../../features/collector/history_screen.dart';
import '../../features/collector/home_screen.dart';
import '../../features/collector/record_collection_screen.dart';
import '../../features/collector/redeem_screen.dart';
import '../../features/collector/scan_screen.dart';
import '../../features/collector/search_screen.dart';
import '../../features/collector/success_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    if (state.uri.path == '/admin') return '/admin/dashboard';
    if (state.uri.path == '/collector') return '/collector/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) =>
          AdminShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/schools',
          builder: (context, state) => const SchoolsScreen(),
        ),
        GoRoute(
          path: '/admin/beneficiaries',
          builder: (context, state) => const BeneficiariesScreen(),
        ),
        GoRoute(
          path: '/admin/beneficiaries/new',
          builder: (context, state) => const RegisterBeneficiaryScreen(),
        ),
        GoRoute(
          path: '/admin/beneficiaries/:id',
          builder: (context, state) => BeneficiaryProfileScreen(
            beneficiaryId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/admin/print',
          builder: (context, state) => const PrintCardsScreen(),
        ),
        GoRoute(
          path: '/admin/materials',
          builder: (context, state) => const MaterialsScreen(),
        ),
        GoRoute(
          path: '/admin/rewards',
          builder: (context, state) => const RewardsScreen(),
        ),
        GoRoute(
          path: '/admin/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const UsersScreen(),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) =>
          CollectorShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/collector/home',
          builder: (context, state) => const CollectorHomeScreen(),
        ),
        GoRoute(
          path: '/collector/search',
          builder: (context, state) => const CollectorSearchScreen(),
        ),
        GoRoute(
          path: '/collector/history',
          builder: (context, state) => const CollectorHistoryScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/collector/scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/collector/beneficiary/:id',
      builder: (context, state) =>
          BeneficiaryCardScreen(beneficiaryId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'collect',
          builder: (context, state) => RecordCollectionScreen(
            beneficiaryId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: 'redeem',
          builder: (context, state) =>
              RedeemScreen(beneficiaryId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: '/collector/success',
      builder: (context, state) => SuccessScreen(
        action: state.uri.queryParameters['action'] ?? 'collect',
        points: int.tryParse(state.uri.queryParameters['points'] ?? '0') ?? 0,
        balance: int.tryParse(state.uri.queryParameters['balance'] ?? '0') ?? 0,
        beneficiaryId: state.uri.queryParameters['beneficiary'] ?? '',
      ),
    ),
  ],
  errorBuilder: (context, state) => const LoginScreen(),
);
