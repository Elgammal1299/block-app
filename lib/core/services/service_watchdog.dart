import 'dart:async';
import 'package:app_block/core/services/platform_channel_service.dart';
import 'package:app_block/core/utils/app_logger.dart';

class ServiceWatchdog {
  final PlatformChannelService _platformService;
  Timer? _timer;
  bool _isServiceAlive = true;

  ServiceWatchdog(this._platformService);

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkHealth();
    });
    AppLogger.i('Service Watchdog started');
  }

  void stop() {
    _timer?.cancel();
    AppLogger.i('Service Watchdog stopped');
  }

  Future<void> _checkHealth() async {
    try {
      final bool running = await _platformService.isServiceRunning();

      if (!running && _isServiceAlive) {
        AppLogger.w(
          'Service Watchdog: Monitoring service is NOT running! Attempting restart...',
        );
        await _platformService.startMonitoringService();
        await _platformService.startUsageTrackingService();
        _isServiceAlive = false;
      } else if (running) {
        if (!_isServiceAlive) {
          AppLogger.i('Service Watchdog: Service recovered successfully.');
        }
        _isServiceAlive = true;
      }
    } catch (e, stack) {
      AppLogger.e('Service Watchdog check failed', e, stack);
    }
  }

  bool get isServiceAlive => _isServiceAlive;
}
