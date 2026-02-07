import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class UnlockChallengeDialog extends StatefulWidget {
  final String challengeType;

  const UnlockChallengeDialog({super.key, required this.challengeType});

  @override
  State<UnlockChallengeDialog> createState() => _UnlockChallengeDialogState();
}

class _UnlockChallengeDialogState extends State<UnlockChallengeDialog> {
  // Math Challenge State
  late int _mathA, _mathB, _mathResult;
  late String _mathOperator;
  final TextEditingController _mathController = TextEditingController();

  // Quote Challenge State
  late String _selectedQuote;
  final TextEditingController _quoteController = TextEditingController();

  // Timer Challenge State
  int _timeLeft = 15;
  Timer? _timer;

  bool _isSolved = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeChallenge();
  }

  void _initializeChallenge() {
    switch (widget.challengeType) {
      case AppConstants.challengeMath:
        final random = math.Random();
        _mathA = random.nextInt(20) + 5;
        _mathB = random.nextInt(15) + 2;
        final opType = random.nextInt(2);
        if (opType == 0) {
          _mathOperator = '+';
          _mathResult = _mathA + _mathB;
        } else {
          _mathOperator = '×';
          _mathResult = _mathA * _mathB;
        }
        break;

      case AppConstants.challengeQuote:
        final random = math.Random();
        _selectedQuote = AppConstants
            .unblockQuotes[random.nextInt(AppConstants.unblockQuotes.length)];
        break;

      case AppConstants.challengeTimer:
        _timeLeft = 15;
        _startTimer();
        break;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        setState(() {
          _isSolved = true;
        });
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mathController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _errorMessage = null;
    });

    if (widget.challengeType == AppConstants.challengeMath) {
      if (int.tryParse(_mathController.text) == _mathResult) {
        setState(() => _isSolved = true);
      } else {
        setState(() => _errorMessage = 'الإجابة غير صحيحة، حاول مجدداً');
      }
    } else if (widget.challengeType == AppConstants.challengeQuote) {
      if (_quoteController.text.trim() == _selectedQuote.trim()) {
        setState(() => _isSolved = true);
      } else {
        setState(
          () => _errorMessage = 'الجملة غير مطابقة، تأكد من كتابتها بدقة',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getChallengeIcon(),
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              _getChallengeTitle(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              _getChallengeSubtitle(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Challenge Content
            _buildChallengeContent(theme),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSolved
                        ? () => Navigator.pop(context, true)
                        : (widget.challengeType == AppConstants.challengeTimer
                              ? null
                              : _validate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSolved
                          ? Colors.green
                          : theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isSolved
                          ? 'تأكيد'
                          : (widget.challengeType == AppConstants.challengeTimer
                                ? 'انتظر...'
                                : 'تحقق'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getChallengeIcon() {
    switch (widget.challengeType) {
      case AppConstants.challengeMath:
        return Icons.calculate_outlined;
      case AppConstants.challengeQuote:
        return Icons.edit_note_outlined;
      case AppConstants.challengeTimer:
        return Icons.timer_outlined;
      default:
        return Icons.lock_open;
    }
  }

  String _getChallengeTitle() {
    switch (widget.challengeType) {
      case AppConstants.challengeMath:
        return 'تحدي الرياضيات';
      case AppConstants.challengeQuote:
        return 'تحدي الكتابة';
      case AppConstants.challengeTimer:
        return 'تحدي الصبر';
      default:
        return 'تأكيد فك الحظر';
    }
  }

  String _getChallengeSubtitle() {
    switch (widget.challengeType) {
      case AppConstants.challengeMath:
        return 'قم بحل المسألة التالية لتتمكن من فك حظر التطبيق';
      case AppConstants.challengeQuote:
        return 'قم بكتابة الجملة التالية بدقة لتأكيد قرارك';
      case AppConstants.challengeTimer:
        return 'انتظر انتهاء الوقت للتأكد من رغبتك في فك الحظر';
      default:
        return 'هل أنت متأكد من فك حظر هذا التطبيق؟';
    }
  }

  Widget _buildChallengeContent(ThemeData theme) {
    switch (widget.challengeType) {
      case AppConstants.challengeMath:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$_mathA $_mathOperator $_mathB = ?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _mathController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'أدخل الإجابة',
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onSubmitted: (_) => _validate(),
            ),
          ],
        );

      case AppConstants.challengeQuote:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Text(
                _selectedQuote,
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _quoteController,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'أعد كتابة الجملة هنا',
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onSubmitted: (_) => _validate(),
            ),
          ],
        );

      case AppConstants.challengeTimer:
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: 1 - (_timeLeft / 15),
                strokeWidth: 8,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isSolved ? Colors.green : theme.colorScheme.primary,
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  _timeLeft.toString(),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: _isSolved ? Colors.green : theme.colorScheme.primary,
                  ),
                ),
                const Text('ثانية', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
