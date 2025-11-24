import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: FitbitScreen());
  }
}

class FitbitScreen extends StatefulWidget {
  @override
  _FitbitScreenState createState() => _FitbitScreenState();
}

class _FitbitScreenState extends State<FitbitScreen> {
  static const platform = MethodChannel('com.example.chaquopy/python');
  
  final TextEditingController _controller = TextEditingController();
  
  String _saveStatus = "데이터를 입력해주세요."; // 저장 결과 메시지
  String _countResult = "아직 조회되지 않음";   // 데이터 개수 메시지

  // 1. 데이터 저장 함수
  Future<void> _saveToPython() async {
    String step = _controller.text;
    if (step.isEmpty) return;

    String response;
    try {
      // Kotlin의 saveStep 호출
      final String result = await platform.invokeMethod('saveStep', {"step": step});
      response = result;
    } on PlatformException catch (e) {
      response = "저장 실패: '${e.message}'.";
    }

    setState(() {
      _saveStatus = response;
    });
  }

  // 2. 데이터 개수 조회 함수
  Future<void> _getDbCount() async {
    String response;
    try {
      // Kotlin의 getCount 호출 (리턴값이 int)
      final int result = await platform.invokeMethod('getCount');
      response = "총 데이터 개수: $result개";
    } on PlatformException catch (e) {
      response = "조회 실패: '${e.message}'.";
    }

    setState(() {
      _countResult = response;
    });
  }

  // 3. DB 초기화 함수
  Future<void> _resetDb() async {
    String response;
    try {
      final String result = await platform.invokeMethod('resetDb');
      response = result;
    } on PlatformException catch (e) {
      response = "초기화 실패: '${e.message}'.";
    }

    // 초기화 후 화면 갱신 (개수 0으로 보여주기 위해)
    setState(() {
      _saveStatus = response;
      _countResult = "초기화 됨 (0개)";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fitbit DB Manager")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number, // 숫자 키패드
              decoration: const InputDecoration(
                labelText: "걸음 수 (Step)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveToPython,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text("DB에 저장하기 (Python 실행)", style: TextStyle(color: Colors.white)),
              ),
            ),
            Text(_saveStatus, style: const TextStyle(color: Colors.blueGrey)),

            const Divider(height: 40, thickness: 2),

            // 조회 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _getDbCount,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("저장된 행 개수 확인하기", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _countResult,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30), // 간격 추가

            // 초기화 버튼 (빨간색)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _resetDb,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text("DB 초기화 (데이터 전체 삭제)", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}