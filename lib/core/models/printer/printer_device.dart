class PrinterDevice {
  final String id;
  final String name;
  final String type; // 'bluetooth' or 'network'
  final String address; // MAC for BT, IP for Network
  final int port; // Port for Network (default 9100)
  final String role; // 'cashier', 'kitchen', 'label'
  final bool isAutoCut; // true for large 80mm printers, false for standard 58mm
  bool isActive;
  bool isConnected;

  PrinterDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.port = 9100,
    required this.role,
    this.isAutoCut = false,
    this.isActive = true,
    this.isConnected = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'port': port,
      'role': role,
      'isAutoCut': isAutoCut,
      'isActive': isActive,
    };
  }

  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    return PrinterDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      address: json['address'] as String,
      port: json['port'] as int? ?? 9100,
      role: json['role'] as String,
      isAutoCut: json['isAutoCut'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      isConnected: false,
    );
  }

  PrinterDevice copyWith({
    String? id,
    String? name,
    String? type,
    String? address,
    int? port,
    String? role,
    bool? isAutoCut,
    bool? isActive,
    bool? isConnected,
  }) {
    return PrinterDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      port: port ?? this.port,
      role: role ?? this.role,
      isAutoCut: isAutoCut ?? this.isAutoCut,
      isActive: isActive ?? this.isActive,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

