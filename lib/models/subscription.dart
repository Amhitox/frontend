class Subscription {
  final String subscriptionId;
  final String currentPriceId;
  final String status;
  final bool cancelAtPeriodEnd;
  final DateTime currentPeriodEnd;

  Subscription({
    required this.subscriptionId,
    required this.currentPriceId,
    required this.status,
    required this.cancelAtPeriodEnd,
    required this.currentPeriodEnd,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      subscriptionId: json['subscription_id'] as String,
      currentPriceId: json['current_price_id'] as String,
      status: json['status'] as String,
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool,
      currentPeriodEnd: DateTime.parse(json['current_period_end'] as String),
    );
  }
  Subscription copyWith({
    String? subscriptionId,
    String? currentPriceId,
    String? status,
    bool? cancelAtPeriodEnd,
    DateTime? currentPeriodEnd,
  }) {
    return Subscription(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      currentPriceId: currentPriceId ?? this.currentPriceId,
      status: status ?? this.status,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
    );
  }
}
