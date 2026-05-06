import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class OverviewHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String userName;
  final String userEmail;
  final String avatarUrl;

  const OverviewHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.userName,
    required this.userEmail,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontBold,
                fontSize: AppTheme.fontSizeTitleLarge,
                color: AppTheme.textColor(context),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: AppTheme.fontRegular,
                fontSize: AppTheme.fontSizeBodySmall,
                color: AppTheme.secondaryTextColor(context),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: AppTheme.fontSizeBodyMedium,
                    color: AppTheme.textColor(context),
                  ),
                ),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontFamily: AppTheme.fontRegular,
                    fontSize: AppTheme.fontSizeLabelMedium,
                    color: AppTheme.secondaryTextColor(context),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.all(2.r),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Image.network(
                  avatarUrl,
                  width: 50.w,
                  height: 50.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.person,
                    size: 40.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DashboardMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: iconColor, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTheme.fontRegular,
                  fontSize: AppTheme.fontSizeLabelMedium,
                  color: AppTheme.secondaryTextColor(context),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppTheme.fontBold,
                  fontSize: AppTheme.fontSizeBodyLarge,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final double progress;
  final Color color;

  const DashboardProgressCard({
    super.key,
    required this.title,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontRegular,
                    fontSize: AppTheme.fontSizeLabelMedium,
                    color: AppTheme.secondaryTextColor(context),
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: AppTheme.fontSizeTitleMedium, // Reduced slightly to fit better
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60.w,
                height: 60.w,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: color.withValues(alpha: 0.1),
                  color: color,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: AppTheme.fontBold,
                  fontSize: AppTheme.fontSizeLabelMedium,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardTable extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final VoidCallback? onNewOrderPressed;

  const DashboardTable({
    super.key,
    required this.title,
    required this.subtitle,
    required this.columns,
    required this.rows,
    this.onNewOrderPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontBold,
                      fontSize: AppTheme.fontSizeTitleMedium,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTheme.fontRegular,
                      fontSize: AppTheme.fontSizeLabelMedium,
                      color: AppTheme.secondaryTextColor(context),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onNewOrderPressed ?? () {},
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('New Order',
                    style: TextStyle(
                        color: Colors.white, fontFamily: AppTheme.fontBold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkBackgroundColor
                            : Colors.grey[50]),
                    columns: columns,
                    rows: rows,
                    columnSpacing: 40.w,
                    horizontalMargin: 12.w,
                  ),
                ),
              );
            }
          ),
        ],
      ),
    );
  }
}
