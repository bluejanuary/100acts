class User {
  final String id;
  final String email;
  final String createdAt;

  User({required this.id, required this.email, required this.createdAt});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        email: json['email'],
        createdAt: json['createdAt'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'createdAt': createdAt,
      };
}
