class EmailCheckResult {
  final bool isValid;
  final bool isDeliverable;
  final String email;

  EmailCheckResult({
    required this.isValid,
    required this.isDeliverable,
    required this.email,
  });

  // Mapeia o JSON que a API retorna para o nosso model
  factory EmailCheckResult.fromJson(Map<String, dynamic> json) {
    return EmailCheckResult(
      email: json['email'] ?? '',
      isValid: json['is_valid_format']?['value'] ?? false,
      isDeliverable: json['deliverability'] == 'DELIVERABLE',
    );
  }
}
