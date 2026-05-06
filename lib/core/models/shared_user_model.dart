class SharedUserModel {
  final bool isLogin;
  final String role;
  final int userId;
  final String userName;
  final String email;
  final String baseUrl;
  final String authToken;

  SharedUserModel({
    this.isLogin = false,
    this.role = "",
    this.userId = 0,
    this.userName = "",
    this.email = "",
    this.baseUrl = "",
    this.authToken = "",
  });

  SharedUserModel copyWith({
    bool? isLogin,
    String? role,
    int? userId,
    String? userName,
    String? email,
    String? baseUrl,
    String? authToken,
  }) {
    return SharedUserModel(
      isLogin: isLogin ?? this.isLogin,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      baseUrl: baseUrl ?? this.baseUrl,
      authToken: authToken ?? this.authToken,
    );
  }

  factory SharedUserModel.fromJson(Map<String, dynamic> json) {
    return SharedUserModel(
      isLogin: json['login'] ?? false,
      role: json['role'] ?? "",
      userId: json['user_id'] ?? 0,
      userName: json['username'] ?? "",
      email: json['user_email'] ?? "",
      baseUrl: json['base_url'] ?? "",
      authToken: json['auth_token'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'login': isLogin,
      'role': role,
      'user_id': userId,
      'username': userName,
      'user_email': email,
      'base_url': baseUrl,
      'auth_token': authToken,
    };
  }
}
