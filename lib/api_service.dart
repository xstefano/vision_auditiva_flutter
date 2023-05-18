import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://apivideofetcher.azurewebsites.net';

  static Future<void> sendImage(String base64Image, String filename) async {
    Uri apiUrl = Uri.parse("$baseUrl/Image");
    Map<String, String> headers = {"Content-Type": "application/json"};

    String jsonBody =
        jsonEncode({"imageBase64": base64Image, "filename": filename});

    await http.post(apiUrl, headers: headers, body: jsonBody);
  }

  static Future<void> sendRequest(String function) async {
    Uri apiUrl = Uri.parse("$baseUrl/api/Request/add");
    Map<String, String> headers = {"Content-Type": "application/json"};

    String jsonBody = jsonEncode({
      "id": 0,
      "function": function,
      "imageUrl": "$baseUrl/Image/image",
      "createdAt": DateTime.now().toIso8601String(),
    });

    await http.post(apiUrl, headers: headers, body: jsonBody);
  }

  static Future<String> getLastResponse() async {
    Uri apiUrl = Uri.parse('$baseUrl/api/Reply/getlast');
    final response = await http.get(apiUrl);
    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final result = responseBody['result'];
      final responseValue = result['response'];
      return responseValue;
    } else {
      throw Exception('Failed to get last response');
    }
  }

  static Future<String> getLastRequest() async {
    Uri apiUrl = Uri.parse('$baseUrl/api/Request/getlast');
    final response = await http.get(apiUrl);

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final result = responseBody['result'];
      final responseValue = result['imageUrl'];
      return responseValue;
    } else {
      throw Exception('Failed to get last request');
    }
  }

  static Future<String> getImageDescription() async {
    final response = await http.get(Uri.parse(
        '$baseUrl/api/Vision/describe?imageUrl=https://apivideofetcher.azurewebsites.net/Image/image'));
    return response.body;
  }

  static Future<String> getImageTexto() async {
    final response = await http.get(Uri.parse(
        '$baseUrl/api/Vision/read?imageUrl=https://apivideofetcher.azurewebsites.net/Image/image'));
    return response.body;
  }
}
