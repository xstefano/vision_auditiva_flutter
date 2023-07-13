import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://visionauditiva.azurewebsites.net';
  late String token;

  ApiService({required String username, required String password}) {
    _login(username, password);
  }

  Future<void> _login(String username, String password) async {
    Uri apiUrl = Uri.parse('$baseUrl/api/Authenticate/Login');
    Map<String, String> headers = {"Content-Type": "application/json"};

    String jsonBody = jsonEncode({
      "userName": username,
      "password": password,
    });

    final response = await http.post(apiUrl, headers: headers, body: jsonBody);

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      token = responseBody['token'];
    } else {
      throw Exception('Failed to log in');
    }
  }

  Future<void> sendImage(String base64Image, String filename) async {
    Uri apiUrl = Uri.parse("$baseUrl/Image");
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    };

    String jsonBody =
        jsonEncode({"imageBase64": base64Image, "filename": filename});

    await http.post(apiUrl, headers: headers, body: jsonBody);
  }

  Future<void> sendRequest(String function) async {
    Uri apiUrl = Uri.parse("$baseUrl/api/Request/add");
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    };

    String jsonBody = jsonEncode({
      "id": 0,
      "function": function,
      "imageUrl": "$baseUrl/Image/image",
      "createdAt": DateTime.now().toIso8601String(),
    });

    await http.post(apiUrl, headers: headers, body: jsonBody);
  }

  Future<String> getLastResponse() async {
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

  Future<String> getImageDescription() async {
    final response = await http.get(
        Uri.parse(
            '$baseUrl/api/CognitiveVision/describe?imageUrl=$baseUrl/Image/image'),
        headers: {"Authorization": "Bearer $token"});
    return response.body;
  }

  Future<String> getImageTexto() async {
    final response = await http.get(
        Uri.parse(
            '$baseUrl/api/CognitiveVision/read?imageUrl=$baseUrl/Image/image'),
        headers: {"Authorization": "Bearer $token"});
    return response.body;
  }

  Future<String> getDetectarRostro() async {
    final response = await http.get(
        Uri.parse('https://flaskdockerpy.azurewebsites.net/detectarRostro/'),
        headers: {"Authorization": "Bearer $token"});
    return response.body;
  }

  Future<String> getAnalizarObjetos() async {
    final response = await http.get(
        Uri.parse(
            '$baseUrl/api/CognitiveVision/detectObjects?imageUrl=$baseUrl/Image/image'),
        headers: {"Authorization": "Bearer $token"});
    return response.body;
  }

  // Api para CHATGPT
  Future<String> getResponse(String request) async {
    final response = await http.get(
        
        Uri.parse('$baseUrl/api/CognitiveChat/getResponse?request=$request'),
        headers: {"Authorization": "Bearer $token"});
    return response.body;
  }
}
