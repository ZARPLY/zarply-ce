import 'dart:convert';
import 'package:http/http.dart' as http;

class OvexService {

  
  OvexService({required this.baseUrl, required this.apiKey});
  
  final String baseUrl;
  final String apiKey;
  
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

// Get all accounts from the bearer token bearer token is a JWT token that is used to authenticate the user

Future <List<Map<String, dynamic>>> getAccounts() async {
  final http.Response response = await http.get(
    Uri.parse('$baseUrl/api/v2/accounts'),
    headers: _headers,
  );
  return jsonDecode(response.body);
}

  Future<bool> validateToken() async {
    try {
      final accounts = await getAccounts();
      return accounts.isNotEmpty; // If accounts returned, token is valid
    } catch (_) {
      return false; // Invalid token or network error
    }
  }


}
