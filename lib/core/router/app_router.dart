import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ===================== Screens =====================
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';

import '../../features/hierarchy/presentation/hierarchy_screen.dart';
import '../../features/hierarchy/presentation/units_screen.dart';
import '../../features/hierarchy/presentation/departments_screen.dart';
import '../../features/hierarchy/presentation/rooms_screen.dart';

import '../../features/clinics/presentation/clinics_screen.dart';
import '../../features/plans/presentation/plans_screen.dart';
import '../../features/archive/presentation/archive_screen.dart';

import '../../features/patients/presentation/patients_screen.dart';
import '../../features/patients/presentation/patient_details_screen.dart';
import '../../features/patients/presentation/add_patient_screen.dart';

import '../../features/calculators/presentation/medicalc_list_screen.dart';
import '../../features/calculators/presentation/medicalc_detail_screen.dart';

import '../../features/extra_features_screens.dart';

import '../../features/qr/presentation/qr_scanner_screen.dart';
import '../../features/qr/presentation/qr_generator_screen.dart';

import '../../features/cases/presentation/cases_feed_screen.dart';
import '../../features/cases/presentation/create_case_screen.dart';
import '../../features/cases/presentation/case_detail_screen.dart';
import '../../features/cases/models/case_model.dart';

import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/chat_room_screen.dart';
import '../../features/chat/presentation/start_chat_screen.dart';
import '../../features/chat/models/chat_models.dart';

import '../../features/notifications/presentation/notifications_screen.dart';

// ===================== Models =====================
import '../../features/patients/models/patient_nav_data.dart';

// ===================== Auth =====================
final _supabase = Supabase.instance.client;

/// Auth routes that don't require authentication
const _publicRoutes = ['/login', '/signup', '/forgot-password'];

/// GoRouter with auth redirect guard
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthRefreshNotifier(),
    redirect: (context, state) {
      final isLoggedIn = _supabase.auth.currentSession != null;
      final isPublicRoute = _publicRoutes.contains(state.matchedLocation);

      // If not logged in and trying to access protected route
      if (!isLoggedIn && !isPublicRoute) {
        return '/login';
      }

      // If logged in and trying to access auth routes
      if (isLoggedIn && isPublicRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // ================= Auth =================
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // ================= Main App Shell Routes =================
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: '/ai',
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: '/drugs',
        builder: (context, state) => const DrugHelperScreen(),
      ),
      GoRoute(
        path: '/medicalc',
        builder: (context, state) => const MedicalcListScreen(),
      ),
      GoRoute(
        path: '/medicalc/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'map';
          return MedicalcDetailScreen(calculatorId: id);
        },
      ),
      GoRoute(
        path: '/infusions',
        builder: (context, state) => const InfusionsScreen(),
      ),

      // ================= Hierarchy =================
      GoRoute(
        path: '/hospitals',
        builder: (context, state) => const HierarchyScreen(),
      ),

      GoRoute(
        path: '/units',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            final hospitalId = extra['hospitalId']?.toString() ?? '';
            final hospitalName = extra['hospitalName']?.toString() ?? '';
            return UnitsScreen(
              hospitalName: hospitalName,
              hospitalId: hospitalId,
            );
          }
          final hospital = state.uri.queryParameters['hospital'] ?? '';
          final id = state.uri.queryParameters['id'] ?? '';
          return UnitsScreen(hospitalName: hospital, hospitalId: id);
        },
      ),

      GoRoute(
        path: '/departments',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            final hospitalId = extra['hospitalId']?.toString() ?? '';
            final hospitalName = extra['hospitalName']?.toString() ?? '';
            return DepartmentsScreen(
              hospitalName: hospitalName,
              hospitalId: hospitalId,
            );
          }
          final hospital = state.uri.queryParameters['hospital'] ?? '';
          final id = state.uri.queryParameters['id'] ?? '';
          return DepartmentsScreen(hospitalName: hospital, hospitalId: id);
        },
      ),

      GoRoute(
        path: '/rooms',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return RoomsScreen(
              hospitalId: (extra['hospitalId'] ?? '').toString(),
              hospitalName: (extra['hospitalName'] ?? '').toString(),
              departmentId: (extra['departmentId'] ?? '').toString(),
              departmentName: (extra['departmentName'] ?? '').toString(),
            );
          }

          final hospitalName = state.uri.queryParameters['hospital'] ?? '';
          final hospitalId = state.uri.queryParameters['hospitalId'] ?? '';
          final departmentId = state.uri.queryParameters['departmentId'] ?? '';
          final departmentName = state.uri.queryParameters['departmentName'] ?? '';

          return RoomsScreen(
            hospitalId: hospitalId,
            hospitalName: hospitalName,
            departmentId: departmentId,
            departmentName: departmentName,
          );
        },
      ),

      // ================= Clinics / Plans / Archive =================
      GoRoute(
        path: '/clinics',
        builder: (context, state) => const ClinicsScreen(),
      ),

      GoRoute(
        path: '/clinic-patients',
        builder: (context, state) {
          final clinic = state.uri.queryParameters['clinic'] ?? '';
          return PatientsScreen(hospitalName: clinic, unitName: '_clinic');
        },
      ),

      GoRoute(path: '/plans', builder: (context, state) => const PlansScreen()),
      GoRoute(
        path: '/archive',
        builder: (context, state) => const ArchiveScreen(),
      ),

      // ================= Patients =================
      GoRoute(
        path: '/patients',
        builder: (context, state) {
          final hospital = state.uri.queryParameters['hospital'] ?? '';
          final room = state.uri.queryParameters['room'];
          final unit = state.uri.queryParameters['unit'];
          return PatientsScreen(
            hospitalName: hospital,
            unitName: (room ?? unit ?? ''),
          );
        },
      ),

      GoRoute(
        path: '/patients/add',
        builder: (context, state) {
          final hospital = state.uri.queryParameters['hospital'] ?? '';
          final room = state.uri.queryParameters['room'];
          final unit = state.uri.queryParameters['unit'];
          return AddPatientScreen(
            hospitalName: hospital,
            unitName: (room ?? unit ?? ''),
          );
        },
      ),

      // ================= Patient Details =================
      GoRoute(
        path: '/patient',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is PatientNavData) {
            return PatientDetailsScreen(data: extra);
          }

          final name = state.uri.queryParameters['name'] ?? 'Patient';
          final mrn = state.uri.queryParameters['mrn'] ?? 'MRN';
          final hospital = state.uri.queryParameters['hospital'] ?? '';
          final room = state.uri.queryParameters['room'];
          final unit = state.uri.queryParameters['unit'];

          return PatientDetailsScreen(
            data: PatientNavData(
              patientName: name,
              mrn: mrn,
              hospitalName: hospital,
              unitName: (room ?? unit ?? ''),
            ),
          );
        },
      ),

      GoRoute(
        path: '/hierarchy',
        builder: (context, state) => const HierarchyScreen(),
      ),

      // ================= QR =================
      GoRoute(
        path: '/qr-scan',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/qr-generate',
        builder: (context, state) => const QrGeneratorScreen(),
      ),

      // ================= Cases =================
      GoRoute(
        path: '/cases',
        builder: (context, state) => const CasesFeedScreen(),
      ),
      GoRoute(
        path: '/cases/create',
        builder: (context, state) => const CreateCaseScreen(),
      ),
      GoRoute(
        path: '/cases/detail',
        builder: (context, state) {
          final caseItem = state.extra as CaseModel;
          return CaseDetailScreen(caseItem: caseItem);
        },
      ),

      // ================= Chat =================
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/start',
        builder: (context, state) => const StartChatScreen(),
      ),
      GoRoute(
        path: '/chat/room',
        builder: (context, state) {
          final conversation = state.extra as ChatConversation;
          return ChatRoomScreen(conversation: conversation);
        },
      ),

      // ================= Notifications =================
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});

/// For backward compatibility - use appRouterProvider with ref.read instead
late final GoRouter appRouter;

void initializeAppRouter(WidgetRef ref) {
  appRouter = ref.read(appRouterProvider);
}

/// Auth state change notifier for GoRouter refresh
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    _supabase.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}
