class User {
  final String id; // UUID from auth.uid()
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final bool isPremium;
  final DateTime? trialEndsAt;
  final DateTime? subscriptionRenewsAt;
  final DateTime? subscriptionEndedAt;

  User({
    required this.id,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.isPremium = false,
    this.trialEndsAt,
    this.subscriptionRenewsAt,
    this.subscriptionEndedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isPremium: json['is_premium'] as bool? ?? false,
      trialEndsAt: json['trial_ends_at'] != null
          ? DateTime.parse(json['trial_ends_at'] as String)
          : null,
      subscriptionRenewsAt: json['subscription_renews_at'] != null
          ? DateTime.parse(json['subscription_renews_at'] as String)
          : null,
      subscriptionEndedAt: json['subscription_ended_at'] != null
          ? DateTime.parse(json['subscription_ended_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'created_at': createdAt.toIso8601String(),
      'is_premium': isPremium,
      'trial_ends_at': trialEndsAt?.toIso8601String(),
      'subscription_renews_at': subscriptionRenewsAt?.toIso8601String(),
      'subscription_ended_at': subscriptionEndedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
    bool? isPremium,
    DateTime? trialEndsAt,
    DateTime? subscriptionRenewsAt,
    DateTime? subscriptionEndedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      isPremium: isPremium ?? this.isPremium,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      subscriptionRenewsAt: subscriptionRenewsAt ?? this.subscriptionRenewsAt,
      subscriptionEndedAt: subscriptionEndedAt ?? this.subscriptionEndedAt,
    );
  }

  bool get isTrialActive =>
      isPremium &&
      trialEndsAt != null &&
      trialEndsAt!.isAfter(DateTime.now());

  bool get isSubscriptionActive =>
      isPremium &&
      subscriptionRenewsAt != null &&
      subscriptionRenewsAt!.isAfter(DateTime.now());
}
