import 'dart:math';

class MotivationalQuotes {
  static final Random _random = Random();

  // Motivational quotes in Arabic
  static const List<String> quotesAr = [
    'ركز على هدفك! نجاحك يعتمد على تركيزك الآن.',
    'كل دقيقة تضيعها الآن، ستندم عليها لاحقًا.',
    'المذاكرة الآن أفضل من الندم غدًا.',
    'أنت أقوى من إغراءاتك! ركز.',
    'هل تريد النجاح؟ ابتعد عن المشتتات.',
    'مستقبلك يُصنع الآن، ليس على مواقع التواصل.',
    'التركيز الآن = النجاح غدًا.',
    'دقائق قليلة من التركيز خير من ساعات من التشتت.',
    'أحلامك تنتظرك، لا تضيع وقتك.',
    'اجعل من اليوم يومًا مثمرًا!',
    'النجاح لا يأتي بالصدفة، بل بالتركيز والعمل.',
    'كل محاولة لفتح هذا التطبيق هي فرصة ضائعة للتقدم.',
    'أنت لست بحاجة لهذا التطبيق الآن، أنت بحاجة للتركيز.',
    'تذكر لماذا بدأت! لا تستسلم الآن.',
    'مستقبلك أهم من أي إشعار على فيسبوك.',
    'الوقت لا ينتظر أحدًا، استثمره بحكمة.',
    'أنت تبني مستقبلك الآن، حجر بحجر.',
    'التضحية اليوم تعني النجاح غدًا.',
    'لا تدع هاتفك يسرق أحلامك.',
    'القوة الحقيقية في ضبط النفس.',
  ];

  // Motivational quotes in English
  static const List<String> quotesEn = [
    'Focus on your goal! Your success depends on your concentration now.',
    'Every minute you waste now, you\'ll regret later.',
    'Studying now is better than regret tomorrow.',
    'You are stronger than your temptations! Focus.',
    'Do you want success? Stay away from distractions.',
    'Your future is being made now, not on social media.',
    'Focus now = Success tomorrow.',
    'A few minutes of focus is better than hours of distraction.',
    'Your dreams are waiting for you, don\'t waste your time.',
    'Make today a productive day!',
    'Success doesn\'t come by chance, but by focus and work.',
    'Every attempt to open this app is a missed opportunity for progress.',
    'You don\'t need this app now, you need to focus.',
    'Remember why you started! Don\'t give up now.',
    'Your future is more important than any Facebook notification.',
    'Time waits for no one, invest it wisely.',
    'You are building your future now, brick by brick.',
    'Sacrifice today means success tomorrow.',
    'Don\'t let your phone steal your dreams.',
    'True strength is in self-control.',
  ];

  // Typing challenges - motivational sentences to type
  static const List<String> typingChallenges = [
    'I am focused on my goals and nothing will distract me.',
    'Success requires sacrifice and I choose to sacrifice distractions.',
    'My future is more valuable than temporary entertainment.',
    'I control my time, my time does not control me.',
    'Every moment of focus brings me closer to my dreams.',
  ];

  // Get random Arabic quote
  static String getRandomQuoteAr() {
    return quotesAr[_random.nextInt(quotesAr.length)];
  }

  // Get random English quote
  static String getRandomQuoteEn() {
    return quotesEn[_random.nextInt(quotesEn.length)];
  }

  // Get random quote (defaults to Arabic)
  static String getRandomQuote() {
    return getRandomQuoteAr();
  }

  // Get random typing challenge
  static String getRandomTypingChallenge() {
    return typingChallenges[_random.nextInt(typingChallenges.length)];
  }
}
