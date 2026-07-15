
class ShiftSessionModel {
  final int? idShift;
  final String shiftName;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int startingBalance;
  final int closingBalance;
  final int totalCashExpected;
  final int totalCashActual;
  final int totalNonCash;
  final int status; // 0: Open, 1: Closed
  final String note;
  final String? reconciliationData;
  final int isSynced;
  final int? idRemote;

  ShiftSessionModel({
    this.idShift,
    required this.shiftName,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.startingBalance = 0,
    this.closingBalance = 0,
    this.totalCashExpected = 0,
    this.totalCashActual = 0,
    this.totalNonCash = 0,
    this.status = 0,
    this.note = '',
    this.reconciliationData,
    this.isSynced = 0,
    this.idRemote,
  });

  Map<String, dynamic> toJson() => {
        'id_shift': idShift,
        'shift_name': shiftName,
        'user_id': userId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'starting_balance': startingBalance,
        'closing_balance': closingBalance,
        'total_cash_expected': totalCashExpected,
        'total_cash_actual': totalCashActual,
        'total_non_cash': totalNonCash,
        'status': status,
        'note': note,
        'reconciliation_data': reconciliationData,
        'is_synced': isSynced,
        'id_remote': idRemote,
      };

  factory ShiftSessionModel.fromJson(Map<String, dynamic> json) {
    int parseIntSafe(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return (double.tryParse(val.toString()) ?? 0).toInt();
    }
    return ShiftSessionModel(
      idShift: json['id_shift'] as int?,
      shiftName: json['shift_name'] as String? ?? 'Shift 1',
      userId: json['user_id']?.toString() ?? '',
      startTime: () {
        final raw = json['start_time']?.toString() ?? '';
        final parsed = DateTime.tryParse(raw);
        if (parsed == null) {
          // ignore: avoid_print
          print('[ShiftSessionModel] WARNING: Could not parse start_time="$raw". This will break reconciliation!');
        }
        return parsed ?? DateTime.now();
      }(),
      endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time'].toString()) : null,
      startingBalance: parseIntSafe(json['starting_balance'] ?? json['opening_cash'] ?? json['opening_balance']),
      closingBalance: parseIntSafe(json['closing_balance'] ?? json['closing_cash']),
      totalCashExpected: parseIntSafe(json['total_cash_expected'] ?? json['total_system_cash']),
      totalCashActual: parseIntSafe(json['total_cash_actual'] ?? json['total_actual_cash']),
      totalNonCash: parseIntSafe(json['total_non_cash']),
      status: json['status'] as int? ?? 0,
      note: json['note'] as String? ?? '',
      reconciliationData: json['reconciliation_data'] as String?,
      isSynced: json['is_synced'] as int? ?? 0,
      idRemote: json['id_remote'] as int?,
    );
  }
}

class ShiftConfig {
  final String name;
  final String staffName;
  bool isActive;

  ShiftConfig({
    required this.name,
    this.staffName = '',
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'staff_name': staffName,
        'active': isActive,
      };

  factory ShiftConfig.fromJson(Map<String, dynamic> json) => ShiftConfig(
        name: json['name'] as String? ?? '',
        staffName: json['staff_name']?.toString() ?? '',
        isActive: json['active'] as bool? ?? true,
      );
}
