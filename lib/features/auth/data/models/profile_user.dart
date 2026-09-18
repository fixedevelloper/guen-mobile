/// Reflète com.guentours.security.web.AuthResponse (POST /api/auth/login,
/// POST /api/auth/register, GET /api/auth/me). Ce endpoint ne renvoie aucune
/// statistique (réservations, favoris...) : pour ça il faudra composer avec
/// GET /api/bookings/me côté client.
class ProfileUser {
  final String email;
  final String fullName;
  final String role;
  final String? partnerId;
  final String userId;

  const ProfileUser({
    required this.email,
    required this.fullName,
    required this.role,
    this.partnerId,
    required this.userId,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      partnerId: json['partnerId'] as String?,
      userId: json['userId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role,
      'partnerId': partnerId,
      'userId': userId,
    };
  }
}
