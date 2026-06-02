class PrinterDevice {
  final String id;
  final String name;
  final String type; // 'bluetooth' or 'network'
  final String address; // MAC for BT, IP for Network
  final int port; // Port for Network (default 9100)
  final List<String> roles; // 'cashier', 'kitchen', 'label'
  final List<String> brands; // List of associated brands (for kitchen printers)
  final bool isAutoCut; // true for large 80mm printers, false for standard 58mm
  final int paperSize; // 58 or 80
  final int fontSize; // 1 (normal), 2 (large), etc.
  bool isActive;
  bool isConnected;

  PrinterDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.port = 9100,
    this.roles = const [],
    this.brands = const [],
    this.isAutoCut = false,
    this.paperSize = 58,
    this.fontSize = 1,
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
      'roles': roles,
      'brands': brands,
      'isAutoCut': isAutoCut,
      'paperSize': paperSize,
      'fontSize': fontSize,
      'isActive': isActive,
    };
  }

  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    List<String> parsedBrands = [];
    if (json['brands'] != null) {
      if (json['brands'] is List) {
        parsedBrands = List<String>.from(json['brands']);
      } else if (json['brands'] is String) {
        parsedBrands = [json['brands'].toString()];
      }
    }

    List<String> parsedRoles = [];
    if (json['roles'] != null) {
      parsedRoles = List<String>.from(json['roles']);
    } else if (json['role'] != null) {
      // Backwards compatibility
      parsedRoles = [json['role'].toString()];
    }

    return PrinterDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      address: json['address'] as String,
      port: json['port'] as int? ?? 9100,
      roles: parsedRoles,
      brands: parsedBrands,
      isAutoCut: json['isAutoCut'] as bool? ?? false,
      paperSize: json['paperSize'] as int? ?? 58,
      fontSize: json['fontSize'] as int? ?? 1,
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
    List<String>? roles,
    List<String>? brands,
    bool? isAutoCut,
    int? paperSize,
    int? fontSize,
    bool? isActive,
    bool? isConnected,
  }) {
    return PrinterDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      port: port ?? this.port,
      roles: roles ?? this.roles,
      brands: brands ?? this.brands,
      isAutoCut: isAutoCut ?? this.isAutoCut,
      paperSize: paperSize ?? this.paperSize,
      fontSize: fontSize ?? this.fontSize,
      isActive: isActive ?? this.isActive,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
