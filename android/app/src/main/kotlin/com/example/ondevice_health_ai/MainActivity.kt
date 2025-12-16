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
            if (call.method == "runPython") {
                
                // 1. Flutter에서 보낸 인자 받기
                val name = call.argument<String>("name")

                // 2. Python이 시작되지 않았으면 시작
                if (!Python.isStarted()) {
                    Python.start(AndroidPlatform(this))
                }

                // 3. Python 인스턴스 및 모듈 가져오기
                val py = Python.getInstance()
                val module = py.getModule("hello")      // hello.py 파일

                // 4. 함수 실행 및 결과 받기
                val pyResult = module.callAttr("greet", name).toString()

                result.success(pyResult)

            } else {
                result.notImplemented()
            }
        }
    }
}