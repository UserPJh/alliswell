import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '다 읽 어',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
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

  // GitHub Secrets에서 환경 변수를 사용하도록 수정
  final String serverUrl = Platform.environment['SERVER_URL'] ?? 'http://127.0.0.1:5000/speak'; // GitHub Secrets에서 SERVER_URL 가져오기

  Future<void> _pickImageAndProcess() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.camera);
    if (pickedImage == null) return;

    setState(() {
      _isLoading = true;
      _image = File(pickedImage.path);
      _extractedText = '';
    });

    try {
      final text = await _authService.callVisionApi(pickedImage.path);
      if (text != null && text.trim().isNotEmpty) {
        setState(() => _extractedText = text);
        await _flutterTts.speak(text);

        final response = await http.post(
          Uri.parse(serverUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"text": text}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final audioUrl = data['url'];
          await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
          await _player.play();
        } else {
          print("❌ 서버 오류: ${response.body}");
        }
      } else {
        print("⚠️ Vision API 결과 없음.");
      }
    } catch (e) {
      print("❌ 오류 발생: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('다 읽 어', style: TextStyle(fontSize: 28)),
        centerTitle: true,
        backgroundColor: Colors.indigo[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null)
              Image.file(_image!, height: 250)
            else
              Icon(Icons.image, size: 150, color: Colors.white24),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt, size: 36),
              label: Text(_isLoading ? '처리 중...' : '사진 찍기', style: TextStyle(fontSize: 26)),
              onPressed: _isLoading ? null : _pickImageAndProcess,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 80),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            SizedBox(height: 30),
            _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _extractedText.isNotEmpty ? _extractedText : '텍스트가 여기에 표시됩니다',
                  style: TextStyle(fontSize: 22, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
