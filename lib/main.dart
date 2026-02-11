import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/simulator_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const Simulator8051App());
}

class Simulator8051App extends StatelessWidget {
  const Simulator8051App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SimulatorProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'simulator8051',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    const primary = Color(0xFF000000); // Pure Black
    const background = Color(0xFFFFFFFF); // Pure White
    const surface = Color(0xFFFAFAFA);
    const surfaceVariant = Color(0xFFF5F5F5);
    
    final colorScheme = ColorScheme.light(
      primary: primary,
      secondary: const Color(0xFF666666), // Dark Gray
      tertiary: const Color(0xFF999999), // Medium Gray
      error: const Color(0xFF000000), // Black for errors
      background: background,
      surface: surface,
      surfaceVariant: surfaceVariant,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: const Color(0xFF000000),
      onSurface: const Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // Use SF Pro on Apple devices, Inter elsewhere
      fontFamily: '.SF Pro Text', // Falls back to system font
      fontFamilyFallback: const ['Inter', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI'],
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.41,
          height: 1.2,
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.36,
          height: 1.25,
        ),
        displaySmall: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.26,
          height: 1.3,
        ),
        headlineMedium: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
          height: 1.35,
        ),
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.26,
          height: 1.3,
        ),
        titleMedium: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
          height: 1.35,
        ),
        titleSmall: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.24,
          height: 1.4,
        ),
        bodyLarge: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
          height: 1.47,
        ),
        bodyMedium: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.24,
          height: 1.47,
        ),
        bodySmall: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.08,
          height: 1.38,
        ),
        labelLarge: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
        ),
        labelMedium: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.08,
        ),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ).apply(
        bodyColor: const Color(0xFF000000),
        displayColor: const Color(0xFF000000),
      ),
      
      // AppBar theme - Apple style
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFFF9F9F9),
        foregroundColor: const Color(0xFF000000),
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.05),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
          color: Color(0xFF000000),
        ),
      ),
      
      // Card theme - Apple style with subtle shadows
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Tab bar theme - Apple style
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: Color(0xFF8E8E93),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Color(0xFFE5E5EA),
        labelStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.24,
        ),
      ),
      
      // FAB theme - Apple style
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: primary,
        sizeConstraints: const BoxConstraints.tightFor(
          width: 56,
          height: 56,
        ),
      ),
      
      // Input decoration - Apple style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: const Color(0xFF8E8E93),
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
        ),
      ),
      
      // Button themes - Apple style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          minimumSize: const Size(44, 44), // Apple HIG minimum touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.41,
          ),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      
      // Chip theme - Apple style
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        deleteIconColor: const Color(0xFF8E8E93),
        disabledColor: const Color(0xFFE5E5EA),
        selectedColor: primary.withOpacity(0.15),
        secondarySelectedColor: primary.withOpacity(0.15),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.08,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.08,
        ),
        brightness: Brightness.light,
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E5EA),
        thickness: 0.5,
        space: 1,
      ),
      
      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 24,
        minVerticalPadding: 8,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const primary = Color(0xFFFFFFFF); // Pure White
    const background = Color(0xFF000000); // Pure Black
    const surface = Color(0xFF0A0A0A); // Almost Black
    const surfaceVariant = Color(0xFF1A1A1A);
    
    final colorScheme = ColorScheme.dark(
      primary: primary,
      secondary: const Color(0xFF999999), // Medium Gray
      tertiary: const Color(0xFF666666), // Dark Gray
      error: const Color(0xFFFFFFFF), // White for errors in dark mode
      background: background,
      surface: surface,
      surfaceVariant: surfaceVariant,
      onPrimary: const Color(0xFF000000),
      onSecondary: const Color(0xFF000000),
      onBackground: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFFFFFFFF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: '.SF Pro Text',
      fontFamilyFallback: const ['Inter', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI'],
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.41,
          height: 1.2,
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.36,
          height: 1.25,
        ),
        displaySmall: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.26,
          height: 1.3,
        ),
        headlineMedium: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
          height: 1.35,
        ),
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.26,
          height: 1.3,
        ),
        titleMedium: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
          height: 1.35,
        ),
        titleSmall: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.24,
          height: 1.4,
        ),
        bodyLarge: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
          height: 1.47,
        ),
        bodyMedium: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.24,
          height: 1.47,
        ),
        bodySmall: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.08,
          height: 1.38,
        ),
        labelLarge: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
        ),
        labelMedium: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.08,
        ),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ).apply(
        bodyColor: const Color(0xFFFFFFFF),
        displayColor: const Color(0xFFFFFFFF),
      ),
      
      // AppBar theme - Apple style dark
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: const Color(0xFFFFFFFF),
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.3),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
          color: Color(0xFFFFFFFF),
        ),
      ),
      
      // Card theme - Apple dark
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Tab bar theme - Apple dark
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: Color(0xFF8E8E93),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Color(0xFF38383A),
        labelStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.24,
        ),
      ),
      
      // FAB theme - Apple dark
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: primary,
        sizeConstraints: const BoxConstraints.tightFor(
          width: 56,
          height: 56,
        ),
      ),
      
      // Input decoration - Apple dark
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF38383A),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF38383A),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF8E8E93),
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
        ),
      ),
      
      // Button themes - Apple dark
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.41,
          ),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      
      // Chip theme - Apple dark
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        deleteIconColor: const Color(0xFF8E8E93),
        disabledColor: const Color(0xFF38383A),
        selectedColor: primary.withOpacity(0.2),
        secondarySelectedColor: primary.withOpacity(0.2),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.08,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.08,
        ),
        brightness: Brightness.dark,
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF38383A),
        thickness: 0.5,
        space: 1,
      ),
      
      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 24,
        minVerticalPadding: 8,
      ),
    );
  }
}
