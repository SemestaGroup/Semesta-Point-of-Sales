class PrinterDevice {
  final String id;
  final String name;
  final String type; // 'bluetooth' or 'network'
  final String address; // MAC for BT, IP for Network
  final int port; // Port for Network (default 9100)
  final List<String> roles; // 'cashier', 'kitchen', 'label'
  final List<String> brands; // Legacy fallback
  final Map<String, List<String>> roleBrands; // Brands per role ('kitchen' -> ['A', 'B'])
  /// Product-level exceptions per role. Key = role ('kitchen'/'label'),
  /// Value = list of product IDs (int) that this printer handles exclusively.
  /// A product listed here will be routed to this printer and skipped by all
  /// other printers that would have matched via brand routing.
  final Map<String, List<int>> roleProductExceptions;
  final bool isAutoCut; // true for large 80mm printers, false for standard 58mm
  final bool isRawFontA; // true = send ESC M 0 byte, false = bypass raw font override
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
    this.roleBrands = const {},
    this.roleProductExceptions = const {},
    this.isAutoCut = false,
    this.isRawFontA = true,
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
      'roleBrands': roleBrands,
      'roleProductExceptions': roleProductExceptions,
      'isAutoCut': isAutoCut,
      'isRawFontA': isRawFontA,
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

    Map<String, List<String>> parsedRoleBrands = {};
    if (json['roleBrands'] != null) {
      if (json['roleBrands'] is Map) {
        (json['roleBrands'] as Map).forEach((key, value) {
          if (value is List) {
             parsedRoleBrands[key.toString()] = List<String>.from(value);
          }
        });
      }
    } else {
      // Backwards compatibility migration
      if (parsedRoles.isNotEmpty && parsedBrands.isNotEmpty) {
        for (var role in parsedRoles) {
          if (role == 'kitchen' || role == 'label') {
            parsedRoleBrands[role] = List<String>.from(parsedBrands);
          }
        }
      }
    }

    // Parse roleProductExceptions — new field, default empty
    Map<String, List<int>> parsedRoleProductExceptions = {};
    if (json['roleProductExceptions'] != null && json['roleProductExceptions'] is Map) {
      (json['roleProductExceptions'] as Map).forEach((key, value) {
        if (value is List) {
          parsedRoleProductExceptions[key.toString()] = value
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((id) => id > 0)
              .toList();
        }
      });
    }

    return PrinterDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      address: json['address'] as String,
      port: json['port'] as int? ?? 9100,
      roles: parsedRoles,
      brands: parsedBrands,
      roleBrands: parsedRoleBrands,
      roleProductExceptions: parsedRoleProductExceptions,
      isAutoCut: json['isAutoCut'] as bool? ?? false,
      isRawFontA: json['isRawFontA'] as bool? ?? true,
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
    Map<String, List<String>>? roleBrands,
    Map<String, List<int>>? roleProductExceptions,
    bool? isAutoCut,
    bool? isRawFontA,
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
      roleBrands: roleBrands ?? this.roleBrands,
      roleProductExceptions: roleProductExceptions ?? this.roleProductExceptions,
      isAutoCut: isAutoCut ?? this.isAutoCut,
      isRawFontA: isRawFontA ?? this.isRawFontA,
      paperSize: paperSize ?? this.paperSize,
      fontSize: fontSize ?? this.fontSize,
      isActive: isActive ?? this.isActive,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
