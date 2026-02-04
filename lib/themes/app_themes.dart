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
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: ColorScheme.fromSeed(
              seedColor: kAppColor,
              brightness: Brightness.light,
            ).primary,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
      ),
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
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: ColorScheme.fromSeed(
              seedColor: kAppColor,
              brightness: Brightness.dark,
            ).primary,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
      ),
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
      fontFamily: 'Google Sans Flex',
      appBarTheme: AppBarTheme(
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Google Sans Flex',
          fontSize: 24,
          fontVariations: [
            FontVariation('wght', 900),
            FontVariation('ROND', 100),
            FontVariation('wdth', 125),
          ],
          color: ColorScheme.fromSeed(
            seedColor: kAppColor,
            brightness: Brightness.light,
          ).onSurface,
        ),
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
        extendedTextStyle: TextStyle(
          fontFamily: 'Google Sans Flex',
          fontVariations: [
            FontVariation('wght', 700),
            FontVariation('ROND', 100),
            FontVariation('wdth', 125),
          ],
          color: ColorScheme.fromSeed(
            seedColor: kAppColor,
            brightness: Brightness.dark,
          ).onSurface,
        ),
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
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
      popupMenuTheme: PopupMenuThemeData(
        elevation: 1,
        color: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.light,
        ).surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderSide: BorderSide(width: 0)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: BorderSide(
            color: ColorScheme.fromSeed(
              seedColor: kAppColor,
              brightness: Brightness.light,
            ).primary,
            width: 1,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.light,
        ).surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.light,
        ).surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  static ThemeData floridDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kAppColor,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Google Sans Flex',
      appBarTheme: AppBarThemeData(
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Google Sans Flex',
          fontSize: 24,
          fontVariations: [
            FontVariation('wght', 900),
            FontVariation('ROND', 100),
            FontVariation('wdth', 125),
          ],
          color: ColorScheme.fromSeed(
            seedColor: kAppColor,
            brightness: Brightness.dark,
          ).onSurface,
        ),
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
        extendedTextStyle: TextStyle(
          fontFamily: 'Google Sans Flex',
          fontVariations: [
            FontVariation('wght', 700),
            FontVariation('ROND', 100),
            FontVariation('wdth', 125),
          ],
          color: ColorScheme.fromSeed(
            seedColor: kAppColor,
            brightness: Brightness.dark,
          ).onSurface,
        ),
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
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
        ).onPrimaryFixedVariant,
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: ColorScheme.fromSeed(
                seedColor: kAppColor,
                brightness: Brightness.dark,
              ).onInverseSurface,
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
        ).onSurface,
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
      popupMenuTheme: PopupMenuThemeData(
        elevation: 1,
        color: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.dark,
        ).surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderSide: BorderSide(width: 0)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: BorderSide(
            color: ColorScheme.fromSeed(
              seedColor: kAppColor,
              brightness: Brightness.dark,
            ).primary,
            width: 1,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.dark,
        ).surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColorScheme.fromSeed(
          seedColor: kAppColor,
          brightness: Brightness.dark,
        ).surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
