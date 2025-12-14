# 🎨 Theme Implementation Guide

دليل شامل لكيفية تطبيق الـ Dark/Light Theme في التطبيق باستخدام `AppTheme` وألوان فيسبوك.

---

## ✅ الوضع الحالي - كل شيء جاهز!

التطبيق **بالفعل مُعد بالكامل** لاستخدام `AppTheme` مع دعم كامل للوضع الداكن والفاتح! 🎉

---

## 🏗️ البنية المُطبقة حالياً

### 1️⃣ **ملف الـ Theme الرئيسي**

📁 `lib/core/theme/app_theme.dart`

```dart
class AppTheme {
  // Light Theme - Facebook Style
  static ThemeData get lightTheme { ... }

  // Dark Theme - Facebook Dark Mode Style
  static ThemeData get darkTheme { ... }
}
```

**المميزات:**
- ✅ Light Theme بألوان فيسبوك
- ✅ Dark Theme بألوان فيسبوك الداكنة
- ✅ تصميم مسطح (Flat Design)
- ✅ Material 3

---

### 2️⃣ **إدارة حالة الـ Theme**

📁 `lib/feature/ui/view_model/theme_cubit/`

#### **ThemeCubit** - يدير الوضع الداكن/الفاتح

```dart
class ThemeCubit extends Cubit<ThemeState> {
  // تحميل الوضع المحفوظ
  Future<void> loadTheme() async { ... }

  // تبديل الوضع
  Future<void> toggleTheme() async { ... }

  // تعيين الوضع مباشرة
  Future<void> setDarkMode(bool value) async { ... }
}
```

**الحالات:**
- `ThemeInitial` - الحالة الأولية
- `ThemeLoading` - جاري التحميل
- `ThemeLoaded(isDarkMode)` - الوضع جاهز

---

### 3️⃣ **التطبيق في main.dart**

📁 `lib/main.dart`

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      bloc: getIt<ThemeCubit>(),
      builder: (context, themeState) {
        final isDarkMode = themeState is ThemeLoaded
            ? themeState.isDarkMode
            : false;

        return MaterialApp(
          // 🎨 استخدام AppTheme
          theme: AppTheme.lightTheme,      // ✅ فيسبوك Light
          darkTheme: AppTheme.darkTheme,   // ✅ فيسبوك Dark
          themeMode: isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          ...
        );
      },
    );
  }
}
```

**كيف يعمل:**
1. `ThemeCubit` يتم إنشاؤه عبر GetIt
2. `BlocBuilder` يستمع للتغييرات
3. عند تغيير الحالة، يتم إعادة بناء MaterialApp
4. MaterialApp يختار الـ theme المناسب تلقائياً

---

### 4️⃣ **زر تبديل الوضع في HomeScreen**

📁 `lib/feature/ui/view/screens/home_screen.dart`

```dart
// في AppBar actions
BlocBuilder<ThemeCubit, ThemeState>(
  bloc: getIt<ThemeCubit>(),
  builder: (context, state) {
    final isDarkMode = state is ThemeLoaded
        ? state.isDarkMode
        : false;

    return IconButton(
      icon: Icon(
        isDarkMode ? Icons.light_mode : Icons.dark_mode,
      ),
      tooltip: isDarkMode
          ? localizations.lightMode
          : localizations.darkMode,
      onPressed: () {
        getIt<ThemeCubit>().toggleTheme();
      },
    );
  },
)
```

**كيف يعمل:**
1. المستخدم يضغط على الزر
2. `toggleTheme()` يتم استدعاؤه
3. ThemeCubit يغير الحالة ويحفظها
4. BlocBuilder في main.dart يكتشف التغيير
5. التطبيق كله يتحدث تلقائياً! 🎉

---

### 5️⃣ **التخزين المحلي**

📁 `lib/feature/data/repositories/settings_repository.dart`

```dart
class SettingsRepository {
  // قراءة الوضع المحفوظ
  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dark_mode') ?? false; // افتراضي: فاتح
  }

  // حفظ الوضع
  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }
}
```

**الميزة:**
- ✅ الوضع يُحفظ تلقائياً
- ✅ يتم استعادته عند فتح التطبيق
- ✅ يستمر حتى بعد إغلاق التطبيق

---

## 🎯 كيفية الاستخدام

### للمستخدم النهائي:

1. **فتح التطبيق** → الوضع المحفوظ يُحمل تلقائياً
2. **الضغط على أيقونة الثيم** في AppBar (🌙/☀️)
3. **التطبيق يتحول فوراً** للوضع الآخر
4. **الوضع يُحفظ تلقائياً** للمرة القادمة

---

### للمطور:

#### 🔸 الوصول للـ ThemeCubit:

```dart
final themeCubit = getIt<ThemeCubit>();
```

#### 🔸 تبديل الوضع:

```dart
getIt<ThemeCubit>().toggleTheme();
```

#### 🔸 تعيين الوضع مباشرة:

```dart
getIt<ThemeCubit>().setDarkMode(true);  // Dark
getIt<ThemeCubit>().setDarkMode(false); // Light
```

#### 🔸 قراءة الوضع الحالي:

```dart
BlocBuilder<ThemeCubit, ThemeState>(
  bloc: getIt<ThemeCubit>(),
  builder: (context, state) {
    if (state is ThemeLoaded) {
      final isDark = state.isDarkMode;
      // استخدم isDark هنا
    }
    return YourWidget();
  },
)
```

---

## 🎨 استخدام الألوان من الـ Theme

### في أي Widget:

```dart
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Container(
    // استخدام ألوان الـ Theme
    color: theme.colorScheme.primary,        // أزرق فيسبوك
    child: Text(
      'Hello',
      style: TextStyle(
        color: theme.colorScheme.onPrimary,  // أبيض
      ),
    ),
  );
}
```

### الألوان المتاحة:

```dart
theme.colorScheme.primary       // #1877F2 (Light) / #2D88FF (Dark)
theme.colorScheme.secondary     // #42B72A (أخضر فيسبوك)
theme.colorScheme.surface       // أبيض / #242526
theme.colorScheme.error         // #E4405F (أحمر/وردي)
theme.scaffoldBackgroundColor   // #F0F2F5 / #18191A
```

### أمثلة عملية:

#### Card بألوان الـ Theme:

```dart
Card(
  color: theme.colorScheme.surface,
  child: Text(
    'Content',
    style: theme.textTheme.bodyMedium,
  ),
)
```

#### Button بألوان الـ Theme:

```dart
ElevatedButton(
  // تلقائياً يستخدم theme.colorScheme.primary
  onPressed: () {},
  child: Text('Click Me'),
)
```

---

## 🔄 دورة حياة الـ Theme

```
1. App Start
   ↓
2. setupGetIt() - ThemeCubit created
   ↓
3. ThemeCubit.loadTheme() - يقرأ من SharedPreferences
   ↓
4. emit(ThemeLoaded(isDarkMode))
   ↓
5. BlocBuilder في main.dart يستقبل الحالة
   ↓
6. MaterialApp يطبق الـ theme المناسب
   ↓
7. User تضغط على زر الثيم
   ↓
8. toggleTheme() - يحفظ ويغير الحالة
   ↓
9. emit(ThemeLoaded(!isDarkMode))
   ↓
10. MaterialApp يُعاد بناؤه بالـ theme الجديد
```

---

## 📱 الشاشات المتأثرة تلقائياً

عند تغيير الوضع، **جميع** الشاشات تتحدث تلقائياً:

✅ HomeScreen (الرئيسية)
✅ ControlScreen (التحكم)
✅ FocusScreen (التركيز)
✅ StatisticsDashboardScreen (الإحصائيات)
✅ BlockedAppsListScreen
✅ ScheduleScreen
✅ FocusListsScreen
✅ وجميع الشاشات الأخرى!

**لماذا؟**
- لأنها **كلها** تستخدم `Theme.of(context)`
- والـ theme يتم توفيره من MaterialApp
- وعند تغيير الـ theme، Flutter يعيد بناء كل شيء تلقائياً!

---

## 🎯 نصائح للتطوير

### 1️⃣ **استخدم Theme.of(context) دائماً**

❌ **خطأ:**
```dart
color: Colors.blue  // ثابت، لن يتغير
```

✅ **صح:**
```dart
color: theme.colorScheme.primary  // يتغير مع الـ theme
```

### 2️⃣ **استخدم TextTheme للنصوص**

✅ **صح:**
```dart
Text(
  'Hello',
  style: theme.textTheme.titleLarge,
)
```

### 3️⃣ **اختبر الوضعين**

- جرب التطبيق في Light Mode
- جرب التطبيق في Dark Mode
- تأكد إن كل شيء واضح وقابل للقراءة

### 4️⃣ **تجنب الألوان الثابتة**

- استخدم `theme.colorScheme.*` بدلاً من `Colors.*`
- استخدم `theme.textTheme.*` بدلاً من `TextStyle` ثابت

---

## 📊 الملخص

| الميزة | الحالة | الملاحظات |
|--------|---------|-----------|
| Light Theme | ✅ جاهز | ألوان فيسبوك |
| Dark Theme | ✅ جاهز | ألوان فيسبوك الداكنة |
| ThemeCubit | ✅ جاهز | إدارة حالة كاملة |
| زر التبديل | ✅ جاهز | في HomeScreen AppBar |
| التخزين المحلي | ✅ جاهز | SharedPreferences |
| Material 3 | ✅ مُفعّل | تصميم حديث |
| تطبيق تلقائي | ✅ يعمل | جميع الشاشات |

---

## 🎉 النتيجة النهائية

التطبيق **كامل ومُعد بالكامل** لاستخدام AppTheme مع:

- ✅ ألوان فيسبوك في Light Mode
- ✅ ألوان فيسبوك الداكنة في Dark Mode
- ✅ تبديل فوري وسلس
- ✅ حفظ تلقائي للاختيار
- ✅ تطبيق على جميع الشاشات

**لا يوجد شيء يحتاج تعديل - كل شيء يعمل! 🚀**

---

**آخر تحديث**: 2025-12-14
**الحالة**: ✅ كامل وجاهز للاستخدام
