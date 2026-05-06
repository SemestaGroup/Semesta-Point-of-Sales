class PrinterDevice {
  final String id;
  final String name;
  final String type; // 'bluetooth' or 'network'
  final String address; // MAC for BT, IP for Network
  final int port; // Port for Network (default 9100)
  final String role; // 'cashier', 'kitchen', 'label'
  final String paperSize; // '58mm' or '80mm'
  bool isActive;
  bool isConnected;

  PrinterDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.port = 9100,
    required this.role,
    this.paperSize = '58mm',
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
      'paperSize': paperSize,
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
      paperSize: json['paperSize'] as String? ?? '58mm',
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
    String? paperSize,
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
      paperSize: paperSize ?? this.paperSize,
      isActive: isActive ?? this.isActive,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

