// import 'dart:ffi';

class Profile {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String createdAt;
  final int rating;
  final String? school;

  const Profile({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    required this.rating,
    this.school,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        createdAt: json['created_at'] as String,
        avatarUrl: json['avatar_url'] as String?,
        rating: json['rating'] as int,
        school: json['school'] as String?,
        
      );

  Profile copyWith({
    String? id,
    String? username,
    String? email,
    String? createdAt,
    int? rating,
    String? avatarUrl,
    String? school
  }) =>
      Profile(
        id: id ?? this.id,
        username: username ?? this.username,
        email: email ?? this.email,
        createdAt: createdAt ?? this.createdAt,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        rating: rating ?? this.rating,
        school: school ?? this.school
      );

  @override
  String toString() => 'Profile(id: $id, username: $username, email: $email)';
}