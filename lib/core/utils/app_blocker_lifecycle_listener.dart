import 'package:flutter/material.dart';
import 'package:app_block/core/utils/app_logger.dart';
import 'package:app_block/core/utils/memory_pressure_listener.dart';

/// AppBlocker Lifecycle Listener
/// 
/// يستمع لـ app lifecycle events ويتعامل معها:
/// - resumed: بدء الاستماع للـ memory pressure
/// - paused: إيقاف الاستماع (اختياري)
/// - detached: تنظيف الموارد
class AppBlockerLifecycleListener extends WidgetsBindingObserver {
  final MemoryPressureListener _memoryListener = MemoryPressureListener();

  void register() {
    WidgetsBinding.instance.addObserver(this);
    AppLogger.i('AppBlockerLifecycleListener: Registered');
  }

  void unregister() {
    WidgetsBinding.instance.removeObserver(this);
    AppLogger.i('AppBlockerLifecycleListener: Unregistered');
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        // App is visible and active
        if (!_memoryListener.isListening) {
          await _memoryListener.startListening();
          AppLogger.d('AppBlockerLifecycleListener: Resumed - memory pressure listening enabled');
        }
        break;

      case AppLifecycleState.paused:
        // App is not visible (might be backgrounded)
        AppLogger.d('AppBlockerLifecycleListener: Paused');
        break;

      case AppLifecycleState.detached:
        // App is being destroyed
        await _memoryListener.stopListening();
        AppLogger.d('AppBlockerLifecycleListener: Detached - memory pressure listening stopped');
        break;

      case AppLifecycleState.hidden:
        // App is hidden but still exists (Flutter 3.13+)
        AppLogger.d('AppBlockerLifecycleListener: Hidden');
        break;

      case AppLifecycleState.inactive:
        // App is inactive
        AppLogger.d('AppBlockerLifecycleListener: Inactive');
        break;
    }
  }
}
