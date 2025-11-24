import 'package:flutter/material.dart';
import 'package:flutter/services.dart';   // MethodChannel 사용을 위해 필요

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: PythonScreen());
  }
}

class PythonScreen extends StatefulWidget {
  @override
  _PythonScreenState createState() => _PythonScreenState();
}

class _PythonScreenState extends State<PythonScreen> {
  // Kotlin과 약속한 채널 이름
  static const platform = MethodChannel('com.example.chaquopy/python');
  
  final TextEditingController _controller = TextEditingController();
  String _result = "결과가 여기에 표시됩니다.";

  // Python 실행 요청 함수
  Future<void> _runPythonCode() async {
    String name = _controller.text;
    String response;
    
    try {
      // Kotlin의 'runPython' 메서드 호출, 인자로 name 전달
      final String result = await platform.invokeMethod('runPython', {"name": name});
      response = result;
    } on PlatformException catch (e) {
      response = "실패: '${e.message}'.";
    }

    setState(() {
      _result = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chaquopy 예제")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: "이름을 입력하세요"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _runPythonCode,
              child: const Text("Python 코드 실행"),
            ),
            const SizedBox(height: 20),
            Text(
              _result,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}