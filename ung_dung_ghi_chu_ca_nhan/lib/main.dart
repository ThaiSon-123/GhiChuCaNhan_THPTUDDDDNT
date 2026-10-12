import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  /// Theme sáng: nền slate nhạt, pastel mềm.
  /// Theme tối: nền xám đậm ấm (không đen tuyệt đối), thẻ nổi khối nhẹ.
  ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7DD3C0),
      brightness: brightness,
      // Ở chế độ tối: primaryContainer giữ tông teal, không bị ngả xám
      primaryContainer: isDark ? const Color(0xFF1F4D46) : null,
      onPrimaryContainer: isDark ? const Color(0xFFA8F0E4) : null,
      surface: isDark ? const Color(0xFF1E2126) : null,
      surfaceContainer: isDark ? const Color(0xFF262A31) : null,
      surfaceContainerHighest: isDark ? const Color(0xFF2E333B) : null,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: isDark ? const Color(0xFF171A1F) : const Color(0xFFF6F7FB),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),
        ),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
      // Đèn đường / icon phụ: xám ấm đọc được trên nền tối
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: isDark ? const Color(0xFFB8BEC9) : null,
        ),
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          color: isDark ? const Color(0xFFD3D7DE) : null,
        ),
        titleMedium: TextStyle(
          color: isDark ? const Color(0xFFF2F4F7) : null,
          fontWeight: FontWeight.bold,
        ),
        // "Tổng N ghi chú"
        labelSmall: TextStyle(
          color: isDark ? const Color(0xFF8B93A1) : null,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF22262D) : scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF262A31) : scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        hintStyle: TextStyle(color: isDark ? const Color(0xFF8B93A1) : null),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF2E333B) : null,
        contentTextStyle: TextStyle(
          color: isDark ? const Color(0xFFF2F4F7) : null,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF22262D) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(
          color: isDark ? const Color(0xFF3A404A) : Colors.grey.shade300,
        ),
        selectedColor: scheme.primaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ghi chú cá nhân',
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _themeMode,
      home: HomeScreen(
        onToggleTheme: (mode) => setState(() => _themeMode = mode),
      ),
    );
  }
}