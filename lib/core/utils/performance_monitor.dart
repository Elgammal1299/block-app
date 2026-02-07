/// Performance Monitor: يراقب الأداء الحالي للتطبيق
/// يُستخدم لـ dynamic throttling بناءً على FPS والأداء العام
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // FPS tracking
  int _frameCount = 0;
  late DateTime _lastFpsCheckTime;
  double _currentFps = 60.0;

  // Performance thresholds
  static const double _excellentFpsThreshold = 55.0; // 55+ FPS
  static const double _goodFpsThreshold = 45.0; // 45-55 FPS
  static const double _poorFpsThreshold = 35.0; // <45 FPS

  // Throttle levels
  static const Duration _throttleExcellent = Duration(milliseconds: 500);
  static const Duration _throttleGood = Duration(milliseconds: 800);
  static const Duration _throttlePoor = Duration(milliseconds: 1200);

  // Memory pressure tracking
  bool _isMemoryPressure = false;

  void initialize() {
    _lastFpsCheckTime = DateTime.now();
  }

  /// Record a frame render
  /// Call this from main thread after each frame
  void recordFrame() {
    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsCheckTime).inMilliseconds;

    // Update FPS every 1 second
    if (elapsed >= 1000) {
      _currentFps = (_frameCount / (elapsed / 1000.0)).clamp(0, 120);
      _frameCount = 0;
      _lastFpsCheckTime = now;
    }
  }

  /// Get current FPS
  double get currentFps => _currentFps;

  /// Get adaptive throttle duration based on current performance
  Duration getAdaptiveThrottleDuration() {
    if (_isMemoryPressure) {
      return _throttlePoor; // Extra conservative when memory is tight
    }

    if (_currentFps >= _excellentFpsThreshold) {
      return _throttleExcellent; // 500ms - responsive
    } else if (_currentFps >= _goodFpsThreshold) {
      return _throttleGood; // 800ms - balanced
    } else {
      return _throttlePoor; // 1200ms - conservative
    }
  }

  /// Get performance level description
  String getPerformanceLevel() {
    if (_currentFps >= _excellentFpsThreshold) {
      return 'Excellent (${_currentFps.toStringAsFixed(1)} FPS)';
    } else if (_currentFps >= _goodFpsThreshold) {
      return 'Good (${_currentFps.toStringAsFixed(1)} FPS)';
    } else if (_currentFps >= _poorFpsThreshold) {
      return 'Fair (${_currentFps.toStringAsFixed(1)} FPS)';
    } else {
      return 'Poor (${_currentFps.toStringAsFixed(1)} FPS)';
    }
  }

  /// Check and update memory pressure
  void checkMemoryPressure(int totalMemoryMb, int usedMemoryMb) {
    _isMemoryPressure = usedMemoryMb > (totalMemoryMb * 0.85); // 85% threshold
  }

  bool get isMemoryPressure => _isMemoryPressure;
}
