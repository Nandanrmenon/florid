import 'package:florid/constants.dart';
import 'package:flutter/material.dart';

class AppThemes {
  // Material Theme (Original)
  static ThemeData materialLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: kAppColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(),
      useMaterial3: true,
    );
  }

  static ThemeData materialDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: kAppColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(),
      useMaterial3: true,
    );
  }

  // Florid Custom Theme
  static ThemeData floridLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kAppColor,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.light,
        ).surfaceContainerLow,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.light,
        ).primary,
        foregroundColor: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.light,
        ).onPrimary,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.light,
        ).surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(width: 0, style: BorderStyle.none),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: ColorScheme.fromSeed(
            seedColor: kAppColor,
            brightness: Brightness.light,
          ).primaryContainer,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        splashBorderRadius: BorderRadius.circular(16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return ColorScheme.fromSeed(
              seedColor: kAppColor,
              brightness: Brightness.light,
            ).primaryContainer;
          }
          return null; // Use the default thumb color
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return ColorScheme.fromSeed(
              seedColor: kAppColor,
              brightness: Brightness.light,
            ).secondary;
          }
          return null; // Use the default track color
        }),
        trackOutlineWidth: WidgetStateProperty.resolveWith<double?>((
          Set<WidgetState> states,
        ) {
          return 1;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.light,
        ).onPrimaryFixedVariant,
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: ColorScheme.fromSeed(
                seedColor: kAppColor,
                brightness: Brightness.light,
              ).onPrimaryContainer,
            );
          }
          return IconThemeData(
            color: ColorScheme.fromSeed(
              seedColor: kAppColor,
              brightness: Brightness.light,
            ).onInverseSurface,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: ColorScheme.fromSeed(
                seedColor: kAppColor,
                brightness: Brightness.light,
              ).onInverseSurface,
            );
          }
          return TextStyle(
            color: ColorScheme.fromSeed(
              seedColor: kAppColor,
              brightness: Brightness.light,
            ).onInverseSurface,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        elevation: 0,
      ),
    );
  }

  static ThemeData floridDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kAppColor,
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.content,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.dark,
        ).surfaceContainerLow,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.dark,
        ).primary,
        foregroundColor: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.dark,
        ).onPrimary,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.dark,
        ).surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(width: 0, style: BorderStyle.none),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: ColorScheme.fromSeed(
            seedColor: kAppColor,
            brightness: Brightness.dark,
          ).primaryContainer,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        splashBorderRadius: BorderRadius.circular(16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return ColorScheme.fromSeed(
              seedColor: kAppColor,
              brightness: Brightness.dark,
            ).primaryContainer;
          }
          return null; // Use the default thumb color
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return ColorScheme.fromSeed(
              seedColor: kAppColor,
              brightness: Brightness.dark,
            ).secondary;
          }
          return null; // Use the default track color
        }),
        trackOutlineWidth: WidgetStateProperty.resolveWith<double?>((
          Set<WidgetState> states,
        ) {
          return 1;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.dark,
        ).primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: ColorScheme.fromSeed(
                seedColor: kAppColor,
                brightness: Brightness.dark,
              ).inverseSurface,
            );
          }
          return IconThemeData(
            color: ColorScheme.fromSeed(
              seedColor: kAppColor,
              brightness: Brightness.dark,
            ).onSurface,
          );
        }),
        indicatorColor: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.dark,
        ).onPrimary,
        labelTextStyle: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: ColorScheme.fromSeed(
                seedColor: kAppColor,
                brightness: Brightness.dark,
              ).onSurface,
            );
          }
          return TextStyle(
            color: ColorScheme.fromSeed(
              seedColor: kAppColor,
              brightness: Brightness.dark,
            ).onSurface,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        elevation: 0,
      ),
    );
  }
}
