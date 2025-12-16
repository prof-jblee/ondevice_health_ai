package com.example.ondevice_health_ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.chaquopy/python"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            
            // Python 시작 확인
            if (!Python.isStarted()) {
                Python.start(AndroidPlatform(this))
            }
            val py = Python.getInstance()
            // 'database.py' 모듈 로드
            val module = py.getModule("database") 

            // 관련 테이블 생성
            module.callAttr("init_db")

            if (call.method == "saveStep") {
                // 1. 데이터 저장 요청
                val timestamp = call.argument<String>("timestamp")
                val step = call.argument<String>("step")
                val pyResult = module.callAttr("insert_step", timestamp, step).toString()
                result.success(pyResult)

            } else if (call.method == "getCount") {
                // 2. 행 개수 조회 요청
                val pyResult = module.callAttr("get_total_count").toInt()
                result.success(pyResult)

            } else if (call.method == "resetDb") {  // <--- [추가된 부분]
                // 3. DB 초기화 요청
                val pyResult = module.callAttr("reset_db").toString()
                result.success(pyResult)

            } else {
                result.notImplemented()
            }
        }
    }
}