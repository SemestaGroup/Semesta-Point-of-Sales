class ClientModel {
  final int userId;
  final String name;
  final String email;
  final String role;
  final String? foto;
  final String baseUrl;
  final String authToken;

  ClientModel({
    this.userId = 0,
    this.name = "",
    this.email = "",
    this.role = "",
    this.foto,
    this.baseUrl = "",
    this.authToken = "",
  });

  ClientModel copyWith({
    int? userId,
    String? name,
    String? email,
    String? role,
    String? foto,
    String? baseUrl,
    String? authToken,
  }) {
    return ClientModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      foto: foto ?? this.foto,
      baseUrl: baseUrl ?? this.baseUrl,
      authToken: authToken ?? this.authToken,
    );
  }

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      role: json['role'] ?? "",
      foto: json['foto'],
      baseUrl: json['base_url'] ?? "",
      authToken: json['auth_token'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'role': role,
      'foto': foto,
      'base_url': baseUrl,
      'auth_token': authToken,
    };
  }
}
