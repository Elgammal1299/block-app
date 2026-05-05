import 'package:flutter/material.dart';

/// Prominent Disclosure Screen — required by Google Play for apps that use
/// AccessibilityServices but are NOT classified as accessibility tools.
/// This screen must appear BEFORE the user grants AccessibilityService permission.
class AccessibilityDisclosureScreen extends StatelessWidget {
  /// Called when the user taps "I Understand — Continue"
  final VoidCallback onAccepted;

  const AccessibilityDisclosureScreen({super.key, required this.onAccepted});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF050A1A),
      body: Stack(
        children: [
          // Background glow top-right
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.orangeAccent.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Background glow bottom-left
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Icon ──────────────────────────────────────────────────
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orangeAccent.withOpacity(0.08),
                        border: Border.all(
                          color: Colors.orangeAccent.withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_rounded,
                        size: 48,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Title ─────────────────────────────────────────────────
                    Text(
                      isArabic
                          ? 'لماذا يحتاج AppBlock\nإلى خدمة إمكانية الوصول؟'
                          : 'Why does AppBlock need\nAccessibility Service?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Subtitle badge ────────────────────────────────────────
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orangeAccent.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        isArabic
                            ? 'إفصاح مهم قبل المتابعة'
                            : 'Important disclosure before continuing',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── What we DO ────────────────────────────────────────────
                    _buildSection(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF4ADE80),
                      title: isArabic ? 'ما الذي تفعله هذه الخدمة' : 'What this service does',
                      bullets: isArabic
                          ? [
                              'تكتشف اسم التطبيق المفتوح حالياً فقط',
                              'تقارنه بقائمة التطبيقات التي اخترتَ أنت حجبها',
                              'تعرض شاشة الحجب إذا كان التطبيق ضمن قائمتك',
                              'تتتبع وقت استخدامك للتطبيقات لإحصاءاتك الخاصة',
                            ]
                          : [
                              'Detects the name of the currently open app',
                              'Compares it to the list of apps YOU chose to block',
                              'Shows a block screen if the app is on your list',
                              'Tracks your app usage for your personal statistics',
                            ],
                    ),
                    const SizedBox(height: 20),

                    // ── What we DON'T DO ──────────────────────────────────────
                    _buildSection(
                      icon: Icons.block_rounded,
                      iconColor: const Color(0xFFF87171),
                      title: isArabic ? 'ما الذي لا تفعله هذه الخدمة' : 'What this service does NOT do',
                      bullets: isArabic
                          ? [
                              'لا تقرأ أي نصوص أو محتوى على شاشتك',
                              'لا تجمع أي بيانات شخصية أو حساسة',
                              'لا ترسل أي معلومات خارج جهازك',
                              'لا تعدّل أو تتحكم في تطبيقات أخرى',
                            ]
                          : [
                              'Does NOT read any text or content on your screen',
                              'Does NOT collect any personal or sensitive data',
                              'Does NOT send any information off your device',
                              'Does NOT modify or control other apps',
                            ],
                    ),
                    const SizedBox(height: 28),

                    // ── Privacy note ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            color: Colors.blue,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'تعمل هذه الخدمة محلياً على جهازك تماماً. '
                                    'بياناتك لا تغادر هاتفك أبداً، '
                                    'ولا نمتلك أي وصول لها.'
                                  : 'This service runs entirely on your device. '
                                    'Your data never leaves your phone, '
                                    'and we have no access to it.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.70),
                                fontSize: 13.5,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Accept button ─────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: onAccepted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isArabic
                              ? 'فهمت — المتابعة لتفعيل الإذن'
                              : 'I Understand — Enable Permission',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Privacy policy link ────────────────────────────────────
                    TextButton(
                      onPressed: () => _openPrivacyPolicy(context),
                      child: Text(
                        isArabic ? 'قراءة سياسة الخصوصية الكاملة' : 'Read full Privacy Policy',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.40),
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withOpacity(0.25),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> bullets,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    // TODO: Replace with your actual privacy policy URL when you have one.
    // You can use url_launcher: await launchUrl(Uri.parse('https://your-privacy-policy-url'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy Policy URL — add your link here'),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}
