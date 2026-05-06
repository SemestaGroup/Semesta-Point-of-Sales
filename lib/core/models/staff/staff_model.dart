class StaffModel {
  final int? id;
  final String? firstname;
  final String? lastname;
  final String? phonenumber;
  final String? email;
  final String? role;
  final String? active;
  final String? password;
  final String? pin;

  StaffModel({
    this.id,
    this.firstname,
    this.lastname,
    this.phonenumber,
    this.email,
    this.role,
    this.active,
    this.password,
    this.pin,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    // API GET returns 'staffid', POST response also returns 'staffid'
    final rawId = json['staffid'] ?? json['id'];
    return StaffModel(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? ''),
      firstname: json['firstname']?.toString(),
      lastname: json['lastname']?.toString(),
      phonenumber: json['phonenumber']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
      active: json['active']?.toString(),
      password: json['password']?.toString(),
      pin: json['pin']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstname': firstname,
      'lastname': lastname,
      'phonenumber': phonenumber,
      'email': email,
      'role': role,
      'active': active,
      'password': password,
      'pin': pin,
    };
  }

  String get fullName => '${firstname ?? ''} ${lastname ?? ''}'.trim();
  
  String get initials {
    if (firstname == null || firstname!.isEmpty) return '?';
    String res = firstname![0].toUpperCase();
    if (lastname != null && lastname!.isNotEmpty) {
      res += lastname![0].toUpperCase();
    }
    return res;
  }
}
