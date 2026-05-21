class CashFlowModel {
  final int? id;
  final String expenseName;
  final String note;
  final int amount;
  final String direction; // 'in' or 'out'
  final String staffName;
  final String staffEmail;
  final String date;        // YYYY-MM-DD
  final String createdAt;   // ISO8601 datetime
  final int idShift;
  final int isSynced;
  final int? remoteId;

  const CashFlowModel({
    this.id,
    required this.expenseName,
    required this.note,
    required this.amount,
    this.direction = 'out',
    required this.staffName,
    required this.staffEmail,
    required this.date,
    required this.createdAt,
    this.idShift = 0,
    this.isSynced = 0,
    this.remoteId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'expense_name': expenseName,
      'note': note,
      'amount': amount,
      'direction': direction,
      'staff_name': staffName,
      'staff_email': staffEmail,
      'date': date,
      'created_at': createdAt,
      'id_shift': idShift,
      'is_synced': isSynced,
      if (remoteId != null) 'remote_id': remoteId,
    };
  }

  factory CashFlowModel.fromMap(Map<String, dynamic> map) {
    return CashFlowModel(
      id: (map['id'] as num?)?.toInt(),
      expenseName: map['expense_name']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      direction: map['direction']?.toString() ?? 'out',
      staffName: map['staff_name']?.toString() ?? '',
      staffEmail: map['staff_email']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
      idShift: (map['id_shift'] as num?)?.toInt() ?? 0,
      isSynced: (map['is_synced'] as num?)?.toInt() ?? 0,
      remoteId: (map['remote_id'] as num?)?.toInt(),
    );
  }

  CashFlowModel copyWith({
    int? id,
    String? expenseName,
    String? note,
    int? amount,
    String? direction,
    String? staffName,
    String? staffEmail,
    String? date,
    String? createdAt,
    int? idShift,
    int? isSynced,
    int? remoteId,
  }) {
    return CashFlowModel(
      id: id ?? this.id,
      expenseName: expenseName ?? this.expenseName,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      staffName: staffName ?? this.staffName,
      staffEmail: staffEmail ?? this.staffEmail,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      idShift: idShift ?? this.idShift,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
    );
  }
}
