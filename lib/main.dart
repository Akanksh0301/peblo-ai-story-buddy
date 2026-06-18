import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/colors.dart';
import 'constants/strings.dart';
import 'screens/story_screen.dart';

void main() {
  // ProviderScope at the root makes every Riverpod provider available and
  // scoped to the app's lifetime.
  runApp(const ProviderScope(child: StoryBuddyApp()));
}

class StoryBuddyApp extends StatelessWidget {
  const StoryBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const StoryScreen(),
    );
  }

  /// Material 3 theme seeded from the brand purple. A single source of truth so
  /// new screens inherit the same look automatically.
  ThemeData _buildTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryPurple,
        primary: AppColors.primaryPurple,
        secondary: AppColors.skyBlue,
        surface: AppColors.cardWhite,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
    );
  }
}
