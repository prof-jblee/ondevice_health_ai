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

    // (1) PATCH /steps (배열 처리)
    router.add('PATCH', '/steps', (Request req) async {
      
      try {

        final params = req.url.queryParameters;
        final valueStr = params['value'];
        final tsStr = params['timestamp'];

        if (valueStr == null || double.tryParse(valueStr) == null) {
          return Response(
            400,
            body: jsonEncode({
              'error': "유효한 숫자 값을 query parameter 'value'로 전달하세요.",
              'example': '/number?value=42&timestamp=1730123456789',
            }),
            headers: {'content-type': 'application/json'},
          );
        }
        
        final ts = (tsStr as num?)?.toInt();
        final sc = (valueStr as num?)?.toInt();
        
        if (ts != null && sc != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(ts);
          final timeString = dt.toIso8601String().replaceAll('T', ' ').split('.')[0];
             
          _controller.add('수신(PATCH) - step:$sc time:$timeString');
             
          // [핵심] 루프 돌며 DB 저장
          await _saveStepToDb(timeString, sc);

          return Response.ok(jsonEncode({'message': '$timeString에 걸음수: $sc 저장됨'}), headers: {
            'content-type': 'application/json',
          });
        }
        
      } catch (e) {
        return Response(400, body: 'Error: $e');
      }
    });

    final handler = const Pipeline().addMiddleware(logRequests()).addHandler(router);
    final server = await serve(handler, InternetAddress.anyIPv4, 3000); // 포트 3000
    
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