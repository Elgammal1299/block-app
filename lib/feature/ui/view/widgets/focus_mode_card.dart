import 'package:flutter/material.dart';

enum FocusModeType {
  study('الدراسة', Icons.school, Colors.purple, Duration(minutes: 25)),
  work('وضع العمل', Icons.work, Colors.blue, Duration(minutes: 50)),
  sleep('النوم', Icons.nightlight_round, Colors.indigo, Duration(hours: 8)),
  meTime('وقت لنفسي', Icons.self_improvement, Colors.pink, Duration(hours: 1)),
  deepWork('العمل العميق', Icons.psychology, Colors.deepPurple, Duration(hours: 1));

  const FocusModeType(this.displayName, this.icon, this.color, this.duration);
  
  final String displayName;
  final IconData icon;
  final Color color;
  final Duration duration;
}

class FocusModeCard extends StatelessWidget {
  final FocusModeType focusMode;
  final VoidCallback onTap;
  final bool isActive;

  const FocusModeCard({
    Key? key,
    required this.focusMode,
    required this.onTap,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: isActive ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive 
            ? BorderSide(color: focusMode.color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      focusMode.color.withOpacity(0.2),
                      focusMode.color.withOpacity(0.1),
                    ],
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Active Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: focusMode.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      focusMode.icon,
                      color: focusMode.color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: focusMode.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'نشط',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Title and Duration
              Text(
                focusMode.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDuration(focusMode.duration),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                _getDescription(focusMode),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours} ساعة${duration.inHours > 1 ? '' : ''}';
    } else {
      return '${duration.inMinutes} دقيقة';
    }
  }

  String _getDescription(FocusModeType mode) {
    switch (mode) {
      case FocusModeType.study:
        return 'حظر جميع التطبيقات المشتتة للتركيز في الدراسة';
      case FocusModeType.work:
        return 'السماح بالتطبيقات الضرورية فقط للعمل';
      case FocusModeType.sleep:
        return 'تقليل الضوء الأزرق والتنبيهات لتحسين النوم';
      case FocusModeType.meTime:
        return 'وقت للاسترخاء والاهتمام بالنفس بدون مقاطعات';
      case FocusModeType.deepWork:
        return 'حظر جميع التطبيقات للتركيز العميق';
    }
  }
}

class FocusModeManager extends StatefulWidget {
  const FocusModeManager({Key? key}) : super(key: key);

  @override
  State<FocusModeManager> createState() => _FocusModeManagerState();
}

class _FocusModeManagerState extends State<FocusModeManager> {
  FocusModeType? _activeMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أوضاع التركيز',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: FocusModeType.values.length,
          itemBuilder: (context, index) {
            final mode = FocusModeType.values[index];
            final isActive = mode == _activeMode;
            
            return FocusModeCard(
              focusMode: mode,
              isActive: isActive,
              onTap: () => _toggleFocusMode(mode),
            );
          },
        ),
      ],
    );
  }

  void _toggleFocusMode(FocusModeType mode) {
    if (_activeMode == mode) {
      // Stop the current focus mode
      setState(() {
        _activeMode = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنهاء وضع التركيز'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Start the new focus mode
      setState(() {
        _activeMode = mode;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('بدأ ${mode.displayName}'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'إلغاء',
            onPressed: () {
              setState(() {
                _activeMode = null;
              });
            },
          ),
        ),
      );
    }
  }
}
