class UserModel {
  final bool success;
  final String message;
  final AuthData? data;

  UserModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class AuthData {
  final String token;
  final String tokenType;
  final UserDetail user;
  final bool requires2fa;
  final String userId;
  final String maskedPhone;

  AuthData({
    required this.token,
    required this.tokenType,
    required this.user,
    this.requires2fa = false,
    this.userId = '',
    this.maskedPhone = '',
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      token: json['token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      user: UserDetail.fromJson(json['user'] ?? {}),
      requires2fa: json['requires_2fa'] ?? false,
      userId: json['user_id']?.toString() ?? '',
      maskedPhone: json['masked_phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}

class UserDetail {
  final dynamic id;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final String? gender;
  final String? avatar;
  final dynamic preference;

  UserDetail({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.gender,
    this.avatar,
    this.preference,
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    return UserDetail(
      id: json['id'],
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      gender: json['gender'],
      avatar: json['avatar'],
      preference: json['preference'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'gender': gender,
      'avatar': avatar,
      'preference': preference,
    };
  }
}
