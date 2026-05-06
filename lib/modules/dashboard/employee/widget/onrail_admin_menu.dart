import 'package:flutter/widgets.dart';
import 'package:semesta_pos/modules/home/admin/views/home_admin_screen.dart';
import 'package:semesta_pos/modules/home/employee/views/home_screen.dart';
import 'package:semesta_pos/modules/member/views/member_view.dart';
import 'package:semesta_pos/modules/product/views/product_view.dart';
import 'package:semesta_pos/modules/profile/employee/views/employee_profile_view.dart';
import 'package:semesta_pos/modules/report/views/report_view.dart';
import 'package:semesta_pos/modules/setting/views/setting_view.dart';

import 'package:semesta_pos/modules/order/views/order_view.dart';
import 'package:semesta_pos/modules/developer/views/database_inspector_screen.dart';

abstract class AdminOnRailMenu {
  static final List<Widget> menuContent = [
    // Content for Home tab
    const HomeAdminScreen(),
    const HomeScreen(),
    const OrderScreen(),
    const MemberScreen(),
    const ProductScreen(),
    const ReportScreen(),
    const SettingScreen(),
    const EmployeeProfileScreen(),
    const EmployeeProfileScreen(),
    const DatabaseInspectorScreen(),
  ];
}
