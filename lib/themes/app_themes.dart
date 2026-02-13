import 'package:florid/constants.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AppThemes {
  // Material Theme (Original)
  static ThemeData materialLightTheme({ColorScheme? colorScheme}) {
    final ColorScheme scheme;
    if (colorScheme != null) {
      scheme = ColorScheme.fromSeed(
        seedColor: colorScheme.primary,
        brightness: Brightness.light,
      );
    } else {
      scheme = ColorScheme.fromSeed(
        seedColor: kAppColor,
        brightness: Brightness.light,
      );
    }

    return ThemeData(
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        labelType: NavigationRailLabelType.all,
        unselectedIconTheme: IconThemeData(color: scheme.onSurface),
        selectedLabelTextStyle: TextStyle(color: scheme.onPrimaryContainer),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(year2023: false),
    );
  }

  static ThemeData materialDarkTheme({ColorScheme? colorScheme}) {
    final ColorScheme scheme;
    if (colorScheme != null) {
      scheme = ColorScheme.fromSeed(
        seedColor: colorScheme.primary,
        brightness: Brightness.dark,
      );
    } else {
      scheme = ColorScheme.fromSeed(
        seedColor: kAppColor,
        brightness: Brightness.dark,
      );
    }

    return ThemeData(
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        labelType: NavigationRailLabelType.all,
        unselectedIconTheme: IconThemeData(color: scheme.onSurface),
        selectedLabelTextStyle: TextStyle(color: scheme.onPrimaryContainer),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(year2023: false),
    );
  }

  // Florid Custom Theme
  static ThemeData floridLightTheme({ColorScheme? colorScheme}) {
    final ColorScheme scheme;
    if (colorScheme != null) {
      scheme = ColorScheme.fromSeed(
        seedColor: colorScheme.primary,
        brightness: Brightness.light,
      );
    } else {
      scheme = ColorScheme.fromSeed(
        seedColor: kAppColor,
        brightness: Brightness.light,
      );
    }

    final ColorScheme darkScheme;
    if (colorScheme != null) {
      darkScheme = ColorScheme.fromSeed(
        seedColor: colorScheme.primary,
        brightness: Brightness.dark,
      );
    } else {
      darkScheme = ColorScheme.fromSeed(
        seedColor: kAppColor,
        brightness: Brightness.dark,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
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
          color: scheme.onSurface,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: TextStyle(
          fontFamily: 'Google Sans Flex',
          fontVariations: [
            FontVariation('wght', 700),
            FontVariation('ROND', 100),
            FontVariation('wdth', 125),
          ],
          color: darkScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
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
            return scheme.primary;
          }
          return null; // Use the default thumb color
        }),
        thumbIcon: WidgetStateProperty.resolveWith<Icon?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return Icon(Symbols.check, color: scheme.onPrimary);
          }
          return null; // Use the default thumb icon
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          return scheme.surfaceDim;
        }),
        trackOutlineWidth: WidgetStateProperty.resolveWith<double?>((
          Set<WidgetState> states,
        ) {
          return -1;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.onPrimaryFixedVariant,
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onPrimaryContainer);
          }
          return IconThemeData(color: scheme.onInverseSurface);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          return TextStyle(color: scheme.onInverseSurface);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainer,
        groupAlignment: 0.0,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        labelType: NavigationRailLabelType.selected,
        unselectedIconTheme: IconThemeData(color: scheme.onSurface),
        selectedLabelTextStyle: TextStyle(color: scheme.onPrimaryContainer),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurface),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 1,
        color: scheme.surfaceContainerHighest,
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
          borderSide: BorderSide(color: scheme.primary, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        checkColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return null; // Use the default check color
        }),
        fillColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return null; // Use the default fill color
        }),
        side: BorderSide(color: scheme.onSurfaceVariant, width: 1.5),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(year2023: false),
    );
  }

  static ThemeData floridDarkTheme({ColorScheme? colorScheme}) {
    final ColorScheme scheme;
    if (colorScheme != null) {
      scheme = ColorScheme.fromSeed(
        seedColor: colorScheme.primary,
        brightness: Brightness.dark,
      );
    } else {
      scheme = ColorScheme.fromSeed(
        seedColor: kAppColor,
        brightness: Brightness.dark,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
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
          color: scheme.onSurface,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: TextStyle(
          fontFamily: 'Google Sans Flex',
          fontVariations: [
            FontVariation('wght', 700),
            FontVariation('ROND', 100),
            FontVariation('wdth', 125),
          ],
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
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
            return scheme.primaryContainer;
          }
          return null; // Use the default thumb color
        }),
        thumbIcon: WidgetStateProperty.resolveWith<Icon?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return Icon(Symbols.check);
          }
          return null; // Use the default thumb icon
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          return scheme.surfaceContainerLowest;
        }),
        trackOutlineWidth: WidgetStateProperty.resolveWith<double?>((
          Set<WidgetState> states,
        ) {
          return -1;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.onPrimaryFixedVariant,
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onInverseSurface);
          }
          return IconThemeData(color: scheme.onSurface);
        }),
        indicatorColor: scheme.onSurface,
        labelTextStyle: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          return TextStyle(color: scheme.onSurface);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainer,
        groupAlignment: 0.0,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        labelType: NavigationRailLabelType.selected,
        unselectedIconTheme: IconThemeData(color: scheme.onSurface),
        selectedLabelTextStyle: TextStyle(color: scheme.onPrimaryContainer),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurface),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 1,
        color: scheme.surfaceContainerHighest,
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
          borderSide: BorderSide(color: scheme.primary, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        checkColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimaryContainer;
          }
          return null; // Use the default check color
        }),
        fillColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primaryContainer;
          }
          return null; // Use the default fill color
        }),
        side: BorderSide(color: scheme.onSurfaceVariant, width: 1.5),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(year2023: false),
    );
  }
}
