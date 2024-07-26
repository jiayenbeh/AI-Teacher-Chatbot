import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqAiService {

  Future getLLaMA3Response(String prompt) async {
    const String endpoint = 'https://api.groq.com/openai/v1/chat/completions';
    const String apiKey = 'your_api_key';

    final Map<String, dynamic> requestBody = {
      "model": "llama3-70b-8192",
      "messages":[{
        "role":"user",
        "content": prompt,
        }],
      "max_tokens":1024,
      "temperature":0.6,
      "top_p":1,
      "frequency_penalty":0,
      "presence_penalty":0,
      "response_format":{
        "type":"text"
      },
      "stream":false};

    final Map<String, String> headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
      "Accept": "application/json"
    };

    final http.Response response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: jsonEncode(requestBody),
    );

    return response;

  }
}
