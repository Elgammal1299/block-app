import 'package:flutter/material.dart';

class FlipClockTimer extends StatelessWidget {
  final int minutes;
  final int seconds;

  const FlipClockTimer({
    super.key,
    required this.minutes,
    required this.seconds,
  });

  @override
  Widget build(BuildContext context) {
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FlipClockDigit(digit: minutesStr[0]),
        const SizedBox(width: 8),
        FlipClockDigit(digit: minutesStr[1]),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            ':',
            style: TextStyle(
              color: Colors.white,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        FlipClockDigit(digit: secondsStr[0]),
        const SizedBox(width: 8),
        FlipClockDigit(digit: secondsStr[1]),
      ],
    );
  }
}

class FlipClockDigit extends StatelessWidget {
  final String digit;

  const FlipClockDigit({super.key, required this.digit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Middle line
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Container(height: 1, color: Colors.black.withOpacity(0.4)),
          ),
          // Digit
          Text(
            digit,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 80,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
