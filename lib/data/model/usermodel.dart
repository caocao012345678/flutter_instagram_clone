class Usermodel {
  String email;
  String username;
  String bio;
  String profile;
  List following;
  List followers;

  // Constructor
  Usermodel(
      this.bio,
      this.email,
      this.followers,
      this.following,
      this.profile,
      this.username,
      );

  factory Usermodel.fromMap(Map<String, dynamic> map) {
    return Usermodel(
      map['bio'] ?? '',
      map['email'] ?? '',
      List.from(map['followers'] ?? []),
      List.from(map['following'] ?? []),
      map['profile'] ?? '',
      map['username'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bio': bio,
      'email': email,
      'followers': followers,
      'following': following,
      'profile': profile,
      'username': username,
    };
  }
}
