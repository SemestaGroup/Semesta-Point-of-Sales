part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const login = _Paths.login;
  static const home = _Paths.home;
  static const dashboardEmployee = _Paths.dashboardEmployee;
  static const employeeProfile = _Paths.employeeProfile;
  static const successPage = _Paths.successPage;
  static const dashboardAdmin = _Paths.dashboardAdmin;
  static const homeAdmin = _Paths.homeAdmin;
  static const category = _Paths.category;
  static const member = _Paths.member;
  static const report = _Paths.report;
  static const setting = _Paths.setting;
  static const sync = _Paths.sync;
  static const staffSelection = _Paths.staffSelection;
  static const inspector = _Paths.inspector;
}

abstract class _Paths {
  static const login = '/login';
  static const sync = '/sync';
  static const home = '/home';
  static const dashboardEmployee = '/dashboard_employee';
  static const employeeProfile = '/profile_employee';
  static const successPage = '/success_page';
  static const dashboardAdmin = '/dashboard_admin';
  static const homeAdmin = '/home_admin';
  static const category = '/category';
  static const member = '/member';
  static const report = '/report';
  static const setting = '/setting';
  static const staffSelection = '/staff_selection';
  static const inspector = '/inspector';
}
