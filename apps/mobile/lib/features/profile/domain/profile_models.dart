class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.phone,
    required this.email,
    required this.city,
    required this.preferredLanguage,
    this.verified = true,
  });

  final String displayName;
  final String phone;
  final String email;
  final String city;
  final String preferredLanguage;
  final bool verified;

  UserProfile copyWith({
    String? displayName,
    String? phone,
    String? email,
    String? city,
    String? preferredLanguage,
    bool? verified,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      verified: verified ?? this.verified,
    );
  }
}
