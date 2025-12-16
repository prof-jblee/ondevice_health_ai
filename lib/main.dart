import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' hide Router;
import 'package:flutter/services.dart';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

void main() {
  runApp(const ZeppLocalServerApp());
}

class ZeppLocalServerApp extends StatefulWidget {
  const ZeppLocalServerApp({super.key});
  @override
  State<ZeppLocalServerApp> createState() => _ZeppLocalServerAppState();
}

class _ZeppLocalServerAppState extends State<ZeppLocalServerApp> {
  HttpServer? _server;
  final _events = <String>[];
  final _controller = StreamController<String>.broadcast();
  late final StreamSubscription<String> _sub;
  
  // [추가] Python 통신 채널
  static const platform = MethodChannel('com.example.chaquopy/python');

  @override
  void initState() {
    super.initState();
    // 로그 리스너
    _sub = _controller.stream.listen((msg) {
      if (!mounted) return;
      setState(() => _events.insert(0, msg));
    });
    _startServer();
  }

  // [추가] DB 저장 헬퍼 함수
  Future<void> _saveStepToDb(String timestamp, int step) async {
    try {
      final String result = await platform.invokeMethod('saveStep', {
        "timestamp": timestamp,
        "step": step.toString(),
      });
      _controller.add("DB 저장 결과: $result");
    } on PlatformException catch (e) {
      _controller.add("DB 에러: ${e.message}");
    }
  }
  
  // [추가] DB 개수 확인 함수 (테스트용)
  Future<void> _checkDbCount() async {
    try {
      final int result = await platform.invokeMethod('getCount');
      _controller.add("현재 DB 저장된 행 개수: $result개");
    } catch (e) {
      _controller.add("조회 실패");
    }
  }

  Future<void> _startServer() async {
    final router = Router();

    // (A) PATCH /steps : 1번 코드의 batch 수신 로직 이식 + (가능하면) DB 저장까지
    router.add('PATCH', '/steps', (Request req) async {
      final body = await req.readAsString();

      try {
        final parsed = jsonDecode(body);
        if (parsed is! List) {
          throw const FormatException('Array expected');
        }

        int sensorCount = 0;
        int sleepCount = 0;
        int dbSavedCount = 0;

        for (final item in parsed) {
          if (item is! Map) {
            _controller.add('[기타] 알 수 없는 데이터 형식 (Map 아님)');
            continue;
          }

          final ts = (item['ts'] as num?)?.toInt() ?? 0;
          final dtIso = (ts != 0)
              ? DateTime.fromMillisecondsSinceEpoch(ts).toIso8601String()
              : 'N/A';
          final timeString = (ts != 0)
              ? DateTime.fromMillisecondsSinceEpoch(ts)
                  .toIso8601String()
                  .replaceAll('T', ' ')
                  .split('.')[0]
              : 'N/A';

          // --- A. 센서 데이터 ---
          if (item.containsKey('step_count')) {
            sensorCount++;

            final step = (item['step_count'] as num?)?.toInt();
            final hr = item['heart_rate'];
            final light = item['light'];
            final restingHr = item['resting_hr'];

            _controller.add(
              '[센서] $dtIso\n'
              '걸음:$step\n'
              '심박수:$hr\n'
              '휴식기 심박수:$restingHr\n'
              '조도:$light\n',
            );

            // ✅ 2번 코드 기능: step_count는 DB 저장 가능하면 저장
            // (timestamp가 유효하고 step이 int이면 저장)
            if (ts != 0 && step != null) {
              await _saveStepToDb(timeString, step);
              dbSavedCount++;
            }
          }
          // --- B. 수면 데이터 ---
          else if (item.containsKey('score')) {
            sleepCount++;

            final score = item['score'];
            final startTime = item['startTime'];
            final endTime = item['endTime'];
            final total = item['totalTime']; // In Bed
            final actual = item['sleepLength']; // Actual Sleep

            final naps = jsonEncode(item['naps']);
            final stages = jsonEncode(item['stages']);

            _controller.add(
              '[수면] $dtIso\n'
              '점수:$score, 시작:$startTime, 종료:$endTime\n'
              '실제 수면:$actual, 인 베드:$total\n'
              '-----------------------------------\n'
              '낮잠:\n$naps\n'
              '-----------------------------------\n'
              '수면 단계:\n$stages',
            );

            // ※ 수면 데이터는 현재 _saveStepToDb밖에 없어서 DB 저장은 생략
          }
          // --- C. 기타 ---
          else {
            _controller.add('[기타] $dtIso\n  알 수 없는 데이터 형식');
          }
        }

        _controller.add(
          '=== 전송 완료 (센서:$sensorCount개, 수면:$sleepCount개, DB저장:$dbSavedCount개) ===',
        );

        return Response.ok(
          jsonEncode({'message': '수신 성공'}),
          headers: {'content-type': 'application/json'},
        );
      } catch (e) {
        return Response(
          400,
          body: jsonEncode({'error': 'JSON 파싱 오류: $e'}),
          headers: {'content-type': 'application/json'},
        );
      }
    });    

    // 서버 실행
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router);

    final server = await serve(handler, InternetAddress.anyIPv4, 3000);

    setState(() => _server = server);
    _controller.add('서버 시작됨: http://${server.address.address}:${server.port}');
  }


  @override
  void dispose() {
    _sub.cancel();
    _controller.close();
    _server?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addr = _server != null
        ? '서버 실행 중: http://${_server!.address.address}:${_server!.port}'
        : '서버 시작 중...';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AmazHealth DB Server'),
          actions: [
            // DB 확인용 버튼 추가
            IconButton(
              icon: const Icon(Icons.storage),
              onPressed: _checkDbCount,
              tooltip: "DB 개수 확인",
            )
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.black12,
              padding: const EdgeInsets.all(12),
              child: SelectableText(addr, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('실시간 로그 및 DB 저장 현황', style: TextStyle(color: Colors.blueGrey)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemBuilder: (_, i) => ListTile(
                  title: Text(_events[i], style: const TextStyle(fontSize: 14)),
                  dense: true,
                ),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: _events.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}