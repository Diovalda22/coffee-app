class UserResponse {
  final String token;
  final Map<String, dynamic> user;

  UserResponse({required this.token, required this.user});

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(token: json['token'], user: json['user']);
  }
}
