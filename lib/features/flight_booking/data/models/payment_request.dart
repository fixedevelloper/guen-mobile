class PaymentRequest {
  final String bookingId;
  final String paymentPlan;   // 'PAY_NOW' ou 'PAY_LATER'
  final String? paymentMethod; // 'CARD', 'ORANGE_MONEY', 'MTN_MONEY', etc.
  final String? cardNumber;
  final String? cardHolderName;
  final String? expiry;
  final String? cvv;
  final String? mobileNumber;

  PaymentRequest({
    required this.bookingId,
    required this.paymentPlan,
    this.paymentMethod,
    this.cardNumber,
    this.cardHolderName,
    this.expiry,
    this.cvv,
    this.mobileNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'paymentPlan': paymentPlan,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (cardNumber != null) 'cardNumber': cardNumber,
      if (cardHolderName != null) 'cardHolderName': cardHolderName,
      if (expiry != null) 'expiry': expiry,
      if (cvv != null) 'cvv': cvv,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
    };
  }
}