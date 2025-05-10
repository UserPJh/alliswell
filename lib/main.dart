import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vision API Example',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _player = AudioPlayer();
  final AuthService _authService = AuthService();
  final FlutterTts _flutterTts = FlutterTts();

  String _extractedText = '';
  File? _image;
  bool _isLoading = false;
  final String serverUrl = 'http://127.0.0.1:5000/speak'; // Flask 서버 URL

  // 이미지 촬영 후 텍스트 처리 및 음성 출력
  Future<void> _pickImageAndProcess() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.camera);
    if (pickedImage == null) return;

    setState(() {
      _isLoading = true;
      _image = File(pickedImage.path);
      _extractedText = '';
    });

    try {
      // 1. Google Vision API를 통해 텍스트 추출
      final text = await _authService.callVisionApi(pickedImage.path);
      if (text != null && text.trim().isNotEmpty) {
        setState(() => _extractedText = text);

        // 2. 텍스트를 TTS로 음성으로 변환하여 바로 재생
        await _flutterTts.speak(text);

        // 3. Flask 서버로 텍스트 전송 (옵션, 필요하다면 사용)
        final response = await http.post(
          Uri.parse(serverUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"text": text}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final audioUrl = data['url'];

          // Flask에서 반환된 mp3 URL로 오디오 재생
          await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
          await _player.play();
        } else {
        }
      } else {}
    } catch (e) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Vision API로 사진 텍스트 읽기")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null) Image.file(_image!, height: 250),
            SizedBox(height: 16),
            Text(
              _extractedText.isNotEmpty
                  ? _extractedText
                  : "사진에서 텍스트를 인식하면 여기에 표시됩니다.",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text(_isLoading ? '처리 중...' : '사진 찍고 읽기'),
              onPressed: _isLoading ? null : _pickImageAndProcess,
            ),
          ],
        ),
      ),
    );
  }
}
