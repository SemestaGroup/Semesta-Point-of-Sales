import 'package:flutter/widgets.dart';
import 'package:semesta_pos/modules/home/admin/views/home_admin_screen.dart';
import 'package:semesta_pos/modules/home/employee/views/home_screen.dart';
import 'package:semesta_pos/modules/member/views/member_view.dart';
import 'package:semesta_pos/modules/profile/employee/views/employee_profile_view.dart';
import 'package:semesta_pos/modules/report/views/report_view.dart';
import 'package:semesta_pos/modules/setting/views/setting_view.dart';
import 'package:semesta_pos/modules/order/views/order_view.dart';
import 'package:semesta_pos/modules/developer/views/database_inspector_screen.dart';
import 'package:semesta_pos/modules/recap/views/recap_view.dart';
import 'package:semesta_pos/modules/kitchen/views/kitchen_view.dart';

abstract class EmployeeOnRailMenu {
  static List<Widget> menuContent = [
    const HomeAdminScreen(), // 0: Dashboard
    const HomeScreen(), // 1: POS
    const OrderScreen(), // 2: Order
    const MemberScreen(), // 3: Customer
    const RecapView(), // 4: Recap
    const ReportScreen(), // 5: Report
    const SettingScreen(), // 6: General
    const EmployeeProfileScreen(), // 7: Profile
    const KitchenView(), // 8: Kitchen
    const DatabaseInspectorScreen(), // 9: Database Inspector
  ];
}
