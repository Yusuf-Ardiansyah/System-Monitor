import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ffi' hide Size;
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:screen_retriever/screen_retriever.dart';

// === RADAR DETEKSI FULL SCREEN WINDOWS ===
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';

// ==========================================
// === FFI SETUP (JEMBATAN C++ KE DART) ===
// ==========================================
typedef GetMetricsC = Int32 Function();
typedef GetMetricsDart = int Function();

typedef GetNetBytesC = Double Function();
typedef GetNetBytesDart = double Function();

final DynamicLibrary dylib = DynamicLibrary.open('sys_metrics.dll');

final GetMetricsDart getCpuUsageNative = dylib
    .lookup<NativeFunction<GetMetricsC>>('getCpuUsage')
    .asFunction();

final GetMetricsDart getMemUsageNative = dylib
    .lookup<NativeFunction<GetMetricsC>>('getMemUsage')
    .asFunction();

final GetNetBytesDart getNetworkOutNative = dylib
    .lookup<NativeFunction<GetNetBytesC>>('getNetworkOutBytes')
    .asFunction();

final GetNetBytesDart getNetworkInNative = dylib
    .lookup<NativeFunction<GetNetBytesC>>('getNetworkInBytes')
    .asFunction();
// ==========================================

double globalPosY = 0;
double globalPosX = 0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  launchAtStartup.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
  );
  await launchAtStartup.enable();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(340, 90),
    center: false,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(false);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setIgnoreMouseEvents(true);

    Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
    double screenHeight = primaryDisplay.size.height;

    // === POSISI SUDAH DITURUNKAN ===
    globalPosY = screenHeight - 46;
    globalPosX = 0;

    await windowManager.setPosition(Offset(globalPosX, globalPosY));
  });

  runApp(const SystemMonitorApp());
}

class SystemMonitorApp extends StatelessWidget {
  const SystemMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S-CM',
      debugShowCheckedModeBanner: false,
      home: const MonitorHomeScreen(),
    );
  }
}

class MonitorHomeScreen extends StatefulWidget {
  const MonitorHomeScreen({super.key});

  @override
  State<MonitorHomeScreen> createState() => _MonitorHomeScreenState();
}

class _MonitorHomeScreenState extends State<MonitorHomeScreen> {
  // 🔥 Default murni tanpa spasi tambahan
  String _uploadSpeedStr = "0.0 KB/s";
  String _downloadSpeedStr = "0.0 KB/s";
  int _cpuUsage = 0;
  int _memUsage = 0;

  double _prevUploadBytes = 0;
  double _prevDownloadBytes = 0;

  Timer? _timer;
  bool _isFullScreenActive = false;

  // === RUMUS RAHASIA: PEMBAGI 8 & JARAK NATURAL 1 SPASI ===
  String _formatSpeed(double rawData) {
    if (rawData <= 0) return "0.0 KB/s"; // Tanpa spasi tambahan

    double realBytesPerSec = rawData / 8.0;
    double kb = realBytesPerSec / 1024.0;

    if (kb < 1024.0) {
      // 🔥 padLeft DIBUANG! Biar jaraknya konsisten cuma 1 spasi dari panah
      return "${kb.toStringAsFixed(1)} KB/s";
    } else {
      double mb = kb / 1024.0;
      return "${mb.toStringAsFixed(2)} MB/s";
    }
  }

  bool _isForegroundFullScreen() {
    try {
      final hwnd = GetForegroundWindow();
      if (hwnd == 0) return false;

      final classNamePtr = wsalloc(256);
      GetClassName(hwnd, classNamePtr, 256);
      String className = classNamePtr.toDartString();
      free(classNamePtr);

      List<String> ignoredClasses = [
        'WorkerW',
        'Progman',
        'Shell_TrayWnd',
        'Shell_SecondaryTrayWnd',
        'NotifyIconOverflowWindow',
        'TrayNotifyWnd',
        'Windows.UI.Core.CoreWindow',
        'XamlExplorerHostIslandWindow',
        'PopupHost',
        'ForegroundStaging',
      ];

      if (ignoredClasses.contains(className)) return false;

      final rect = calloc<RECT>();
      GetWindowRect(hwnd, rect);

      int top = rect.ref.top;
      int left = rect.ref.left;
      int width = rect.ref.right - rect.ref.left;
      int height = rect.ref.bottom - rect.ref.top;

      int screenWidth = GetSystemMetrics(SM_CXSCREEN);
      int screenHeight = GetSystemMetrics(SM_CYSCREEN);
      free(rect);

      if (top >= -2 &&
          top <= 2 &&
          left >= -2 &&
          left <= 2 &&
          width >= (screenWidth - 2) &&
          height >= (screenHeight - 2)) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // === FONT BOLD & SPASI PRESISI TRAFFIC MONITOR ===
  final TextStyle _textStyle = const TextStyle(
    color: Color(0xFF55FF55),
    // 🔥 EMERALD BRIGHT (HIJAU SULTAN TERANG)
    fontSize: 15.0,
    fontFamily: 'Consolas',
    fontWeight: FontWeight.bold,
    letterSpacing: 0.0,
    height: 1.1,
    shadows: [Shadow(offset: Offset(1.0, 1.0), color: Colors.black)],
  );

  @override
  void initState() {
    super.initState();

    try {
      _prevUploadBytes = getNetworkOutNative();
      _prevDownloadBytes = getNetworkInNative();
    } catch (e) {
      _prevUploadBytes = 0;
      _prevDownloadBytes = 0;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        try {
          double currentUploadBytes = getNetworkOutNative();
          double currentDownloadBytes = getNetworkInNative();

          setState(() {
            if (_prevUploadBytes > 0 &&
                currentUploadBytes >= _prevUploadBytes) {
              _uploadSpeedStr = _formatSpeed(
                currentUploadBytes - _prevUploadBytes,
              );
            } else {
              _uploadSpeedStr = "0.0 KB/s";
            }

            if (_prevDownloadBytes > 0 &&
                currentDownloadBytes >= _prevDownloadBytes) {
              _downloadSpeedStr = _formatSpeed(
                currentDownloadBytes - _prevDownloadBytes,
              );
            } else {
              _downloadSpeedStr = "0.0 KB/s";
            }

            _cpuUsage = getCpuUsageNative();
            _memUsage = getMemUsageNative();
          });

          _prevUploadBytes = currentUploadBytes;
          _prevDownloadBytes = currentDownloadBytes;
        } catch (e) {
          setState(() {
            _uploadSpeedStr = "0.0 KB/s";
            _downloadSpeedStr = "0.0 KB/s";
            _cpuUsage = 0;
            _memUsage = 0;
          });
        }

        bool isFull = _isForegroundFullScreen();
        if (_isFullScreenActive != isFull) {
          setState(() {
            _isFullScreenActive = isFull;
          });

          if (isFull) {
            windowManager.setPosition(const Offset(-2000, -2000));
          } else {
            if (globalPosY > 0) {
              windowManager.setPosition(Offset(globalPosX, globalPosY));
              windowManager.setAlwaysOnTop(true);
            }
          }
        } else if (!isFull) {
          windowManager.setAlwaysOnTop(true);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.black.withValues(alpha: 0.01),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 PATEN 1 SPASI MURNI SAJA DI SINI!
                Text("↑: $_uploadSpeedStr", style: _textStyle),
                Text("↓: $_downloadSpeedStr", style: _textStyle),
              ],
            ),
            const SizedBox(width: 12), // Jarak ke CPU/MEM
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CPU: ${_cpuUsage.toString().padLeft(2, ' ')} %",
                  style: _textStyle,
                ),
                Text(
                  "MEM: ${_memUsage.toString().padLeft(2, ' ')} %",
                  style: _textStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
