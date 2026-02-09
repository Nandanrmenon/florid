# Contributing to Florid

Thank you for your interest in contributing to Florid! We welcome contributions from everyone. This guide will help you get started.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Contributing Code](#contributing-code)
  - [Contributing Translations](#contributing-translations)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [Localization Guidelines](#localization-guidelines)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected behavior** vs **actual behavior**
- **Screenshots** if applicable
- **Device information** (Android version, device model)
- **App version** you're using

### Suggesting Features

Feature suggestions are welcome! Please:

- **Check existing feature requests** first
- **Describe the feature** in detail
- **Explain the use case** and why it would be valuable
- **Consider implementation complexity**

### Contributing Code

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit with clear messages (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Contributing Translations

Florid uses Flutter ARB files for localization. The source-of-truth strings live in `lib/l10n/app_en.arb`.

#### Adding a New Language

1. **Create a new ARB file:**
   - Add a file in `lib/l10n/` named `app_<locale>.arb` (e.g., `app_fr.arb`)
   - Copy the structure from `app_en.arb`

2. **Translate all keys:**

   ```json
   {
     "app_name": "Florid",
     "welcome": "Your translation here",
     "search": "Your translation here"
   }
   ```

3. **Regenerate localization classes:**

   ```bash
   flutter gen-l10n
   ```

4. **Test your translations:**
   - Change your device language to the new language
   - Launch the app and verify all strings appear correctly
   - Check that text fits in UI elements (some languages use longer words)

#### Improving Existing Translations

1. Open the relevant ARB file in `lib/l10n/`
2. Update the translation values
3. Ensure translations are:
   - **Accurate** and contextually appropriate
   - **Natural** in the target language
   - **Consistent** with app terminology
4. Test the changes in the app

## Development Setup

### Prerequisites

- Flutter SDK (3.38.7 or higher)
- Dart SDK (3.9.2 or higher)
- Android Studio or VS Code with Flutter extensions
- Android device or emulator for testing

### Setup Steps

1. **Clone the repository:**

   ```bash
   git clone https://github.com/yourusername/florid.git
   cd florid
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

### Project Structure

```
lib/
├── models/          # Data models
├── providers/       # State management (Provider)
├── screens/         # UI screens
├── services/        # API and business logic
├── themes/          # App themes
├── utils/           # Utility functions
├── widgets/         # Reusable widgets
└── main.dart        # App entry point

lib/l10n/           # ARB localization files
```

## Pull Request Process

1. **Update documentation** if you've made changes to APIs or added features
2. **Add/update tests** for new functionality
3. **Follow the style guidelines** below
4. **Ensure the app builds** without errors
5. **Test on a real device** when possible
6. **Update CHANGELOG.md** with notable changes
7. **Link any related issues** in the PR description

### PR Checklist

- [ ] Code follows the project style guidelines
- [ ] Self-review of code completed
- [ ] Comments added for complex logic
- [ ] Documentation updated if needed
- [ ] No new warnings generated
- [ ] Translations added/updated if UI text changed
- [ ] Tested on Android device/emulator

## Style Guidelines

### Dart Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` to check for issues
- Format code with `dart format .`
- Maximum line length: 80 characters (flexible for readability)

### Widget Organization

```dart
class MyWidget extends StatelessWidget {
  // 1. Final fields
  final String title;

  // 2. Constructor
  const MyWidget({super.key, required this.title});

  // 3. Build method
  @override
  Widget build(BuildContext context) {
    // ...
  }

  // 4. Helper methods
  void _helperMethod() {
    // ...
  }
}
```

### Naming Conventions

- **Classes**: `PascalCase` (e.g., `AppDetailsScreen`)
- **Files**: `snake_case` (e.g., `app_details_screen.dart`)
- **Variables/Functions**: `camelCase` (e.g., `downloadApp`)
- **Constants**: `camelCase` (e.g., `maxRetries`)
- **Private members**: prefix with `_` (e.g., `_privateMethod`)

### Comments

- Use `///` for public API documentation
- Use `//` for inline comments
- Explain **why**, not **what** (code should be self-documenting)

```dart
// Good
/// Fetches app details from the repository.
/// Returns null if the app is not found or network error occurs.
Future<FDroidApp?> fetchAppDetails(String packageName) async { ... }

// Bad
// This function gets the app
Future<FDroidApp?> fetchAppDetails(String packageName) async { ... }
```

### UI/UX Guidelines

- **Responsive Design**: Test on different screen sizes
- **Accessibility**: Use semantic labels and ensure good contrast
- **Performance**: Avoid unnecessary rebuilds, use `const` constructors
- **Material Design**: Follow Material 3 guidelines
- **Animations**: Keep animations smooth and purposeful (avoid excessive animation)

## Localization Guidelines

### Adding New Strings

When adding new UI text:

1. **Never hardcode strings** in UI code
2. **Add to all translation files** (at minimum `en.json` and `es.json`)
3. **Use descriptive keys** with underscores:

   ```json
   {
     "error_network_title": "Network Error",
     "error_network_message": "Please check your internet connection",
     "button_retry": "Retry"
   }
   ```

4. **Use the string in code:**
   ```dart
   Text('error_network_title'.tr())
   ```

### Translation Key Naming

Follow this pattern: `[category]_[context]_[element]`

Examples:

- `error_network_title`
- `settings_theme_dark`
- `dialog_delete_confirm`
- `button_download`
- `label_version_name`

### Context for Translators

When adding strings that might be ambiguous, add a comment in the PR:

```
Added "bank" key - refers to river bank, not financial institution
```

## Questions?

If you have questions or need help:

- Open an issue with the `question` label
- Check existing issues and discussions
- Review the documentation in the repository

## License

By contributing to Florid, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to Florid! 🎉
