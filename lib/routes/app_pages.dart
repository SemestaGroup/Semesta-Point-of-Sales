import 'package:get/get.dart';
import 'package:semesta_pos/modules/auth/bindings/auth_binding.dart';
import 'package:semesta_pos/modules/auth/views/login_view.dart';
import 'package:semesta_pos/modules/auth/views/staff_selection_view.dart';
import 'package:semesta_pos/modules/developer/bindings/database_inspector_binding.dart';
import 'package:semesta_pos/modules/developer/views/database_inspector_screen.dart';
import 'package:semesta_pos/modules/category/binding/category_binding.dart';
import 'package:semesta_pos/modules/category/views/category_view.dart';
import 'package:semesta_pos/modules/dashboard/admin/views/dashboard_admin.dart';
import 'package:semesta_pos/modules/home/admin/bindings/home_admin_binding.dart';
import 'package:semesta_pos/modules/home/admin/views/home_admin_screen.dart';
import 'package:semesta_pos/modules/home/employee/views/success_page.dart';
import 'package:semesta_pos/modules/home/employee/bindings/home_binding.dart';
import 'package:semesta_pos/modules/dashboard/employee/views/dashboard_employee.dart';
import 'package:semesta_pos/modules/home/employee/bindings/success_binding.dart';
import 'package:semesta_pos/modules/home/employee/views/home_screen.dart';
import 'package:semesta_pos/modules/member/bindings/member_binding.dart';
import 'package:semesta_pos/modules/member/views/member_view.dart';
import 'package:semesta_pos/modules/profile/employee/bindings/employee_profile_binding.dart';
import 'package:semesta_pos/modules/profile/employee/views/employee_profile_view.dart';
import 'package:semesta_pos/modules/report/bindings/report_binding.dart';
import 'package:semesta_pos/modules/report/views/report_view.dart';
import 'package:semesta_pos/modules/setting/bindings/setting_binding.dart';
import 'package:semesta_pos/modules/setting/views/setting_view.dart';
import 'package:semesta_pos/modules/sync/bindings/sync_binding.dart';
import 'package:semesta_pos/modules/sync/views/sync_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();
  static const initialRoutes = Routes.login;

  static final routes = [
    GetPage(
      name: _Paths.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.staffSelection,
      page: () => const StaffSelectionView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.sync,
      page: () => const SyncView(),
      binding: SyncBinding(),
    ),
    GetPage(
      name: _Paths.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.dashboardEmployee,
      page: () => DashboardEmployeeScreen(),
      // binding: DashboardEmployeeBinding(),
    ),
    GetPage(
      name: _Paths.employeeProfile,
      page: () => const EmployeeProfileScreen(),
      binding: EmployeeProfileBinding(),
    ),
    GetPage(
      name: _Paths.successPage,
      page: () => const SuccessPage(),
      binding: SuccessBinding(),
    ),
    GetPage(
      name: _Paths.dashboardAdmin,
      page: () => DashboardAdminScreen(),
      // binding: DashboardAdminBinding(),
    ),
    GetPage(
      name: _Paths.homeAdmin,
      page: () => const HomeAdminScreen(),
      binding: HomeAdminBinding(),
    ),
    GetPage(
      name: _Paths.category,
      page: () => const CategoryView(),
      binding: CategoryBinding(),
    ),
    GetPage(
      name: _Paths.member,
      page: () => const MemberScreen(),
      binding: MemberBinding(),
    ),
    GetPage(
      name: _Paths.report,
      page: () => const ReportScreen(),
      binding: ReportBinding(),
    ),
    GetPage(
      name: _Paths.setting,
      binding: SettingBinding(),
      page: () => const SettingScreen(),
    ),
    GetPage(
      name: _Paths.inspector,
      page: () => const DatabaseInspectorScreen(),
      binding: DatabaseInspectorBinding(),
    )
  ];
}
