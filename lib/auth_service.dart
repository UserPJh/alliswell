import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final String apiUrl = dotenv.env['VISION_BASE_URL'] ?? 'default_url';
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/cloud-vision'],
  );

  // 구글 로그인 후 액세스 토큰 얻기
  Future<String?> _signInWithGoogle() async {
    try {
      GoogleSignInAccount? account = await _googleSignIn.signIn();
      GoogleSignInAuthentication auth = await account!.authentication;
      return auth.accessToken;
    } catch (e) {
      return null;
    }
  }

  // Vision API 호출
  Future<String?> callVisionApi(String imagePath) async {
    final String base64Image = await encodeImageToBase64(imagePath);
    final String? accessToken = await _signInWithGoogle();

    if (accessToken == null) {
      return null;
    }

    final headers = {
      HttpHeaders.authorizationHeader: 'Bearer $accessToken',
      HttpHeaders.contentTypeHeader: 'application/json',
    };

    final body = jsonEncode({
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'TEXT_DETECTION'}
          ]
        }
      ]
    });

    final response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final textAnnotations = jsonResponse['responses'][0]['textAnnotations'];
      if (textAnnotations != null && textAnnotations.isNotEmpty) {
        return textAnnotations[0]['description'];
      }
    }
    return null;
  }

  // 이미지를 Base64로 인코딩
  Future<String> encodeImageToBase64(String imagePath) async {
    final imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }
}
