import 'package:flutter/material.dart';

class AppColors {
  // Brand & Surfaces
  static const Color primary = Color(0xFF0F172A); // Slate 900
  static const Color primaryLight = Color(0xFF1E293B); // Slate 800
  static const Color accent = Color(0xFF6366F1); // Indigo 500
  static const Color accentLight = Color(0xFFEEF2FF);
  
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color surfaceSubtle = Color(0xFFF1F5F9); // Slate 100
  static const Color border = Color(0xFFE2E8F0); // Slate 200

  // Income & Expense
  static const Color income = Color(0xFF10B981); // Emerald 500
  static const Color incomeDark = Color(0xFF059669);
  static const Color incomeLight = Color(0xFFECFDF5);

  static const Color expense = Color(0xFFF43F5E); // Rose 500
  static const Color expenseDark = Color(0xFFE11D48);
  static const Color expenseLight = Color(0xFFFFF1F2);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.expense),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
    );
  }
}

class CategoryUtils {
  static IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'খাবার':
        return Icons.restaurant_rounded;
      case 'shopping':
      case 'কেনাকাটা':
        return Icons.shopping_bag_rounded;
      case 'salary':
      case 'income':
      case 'বেতন':
        return Icons.account_balance_wallet_rounded;
      case 'transport':
      case 'যাতায়াত':
        return Icons.directions_subway_rounded;
      case 'bills':
      case 'বিল':
        return Icons.receipt_long_rounded;
      case 'entertainment':
      case 'বিনোদন':
        return Icons.movie_rounded;
      case 'health':
      case 'চিকিৎসা':
        return Icons.medical_services_rounded;
      case 'education':
      case 'শিক্ষা':
        return Icons.school_rounded;
      case 'investment':
      case 'বিনিয়োগ':
        return Icons.trending_up_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  static Color getColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'খাবার':
        return const Color(0xFFF97316); // Orange
      case 'shopping':
      case 'কেনাকাটা':
        return const Color(0xFFEC4899); // Pink
      case 'salary':
      case 'income':
      case 'বেতন':
        return const Color(0xFF10B981); // Emerald
      case 'transport':
      case 'যাতায়াত':
        return const Color(0xFF3B82F6); // Blue
      case 'bills':
      case 'বিল':
        return const Color(0xFFEAB308); // Amber
      case 'entertainment':
      case 'বিনোদন':
        return const Color(0xFF8B5CF6); // Purple
      case 'health':
      case 'চিকিৎসা':
        return const Color(0xFFEF4444); // Red
      case 'education':
      case 'শিক্ষা':
        return const Color(0xFF06B6D4); // Cyan
      case 'investment':
      case 'বিনিয়োগ':
        return const Color(0xFF14B8A6); // Teal
      default:
        return const Color(0xFF64748B); // Slate
    }
  }
}
