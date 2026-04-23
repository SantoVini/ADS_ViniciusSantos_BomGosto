import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/email_check_result.dart';
import '../constants/app_constants.dart';

class EmailService {
  Future<EmailCheckResult> checkEmail(String email) async {
    final uri = Uri.parse(
      '${AppConstants.emailApiBaseUrl}?api_key=${AppConstants.emailApiKey}&email=$email',
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return EmailCheckResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Erro na API: ${response.statusCode}');
  }
}
