import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WhatsNewSection {
  WhatsNewSection({required this.title, required this.items});

  final String title;
  final List<String> items;
}

class WhatsNewData {
  WhatsNewData({required this.version, required this.sections});

  final String version;
  final List<WhatsNewSection> sections;
}

class WhatsNewLoader {
  static Future<WhatsNewData?> loadForVersion(String version) async {
    try {
      final changelog = await _loadChangelog();
      if (changelog == null || changelog.trim().isEmpty) {
        debugPrint('[WhatsNew] Changelog asset missing or empty');
        return null;
      }
      final candidates = <String>{version};
      final withoutBuild = version.contains('+')
          ? version.substring(0, version.indexOf('+'))
          : null;
      if (withoutBuild != null) {
        candidates.add(withoutBuild);
      }

      WhatsNewData? parsed;
      for (final candidate in candidates) {
        final block = _extractBlock(changelog, candidate);
        if (block != null) {
          parsed = _parseBlock(candidate, block);
          if (parsed != null) break;
        }
      }

      if (parsed != null) return parsed;

      // Fallback: show the latest entry in the changelog.
      final firstHeading = RegExp(
        '^##\\s+v?([^\\s]+)',
        multiLine: true,
      ).firstMatch(changelog);
      if (firstHeading == null) return null;

      final latestVersion = firstHeading.group(1)!;
      final latestBlock = _extractBlock(changelog, latestVersion);
      return latestBlock != null
          ? _parseBlock(latestVersion, latestBlock)
          : null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _loadChangelog() async {
    const candidates = [
      'CHANGELOGS.md',
      'assets/CHANGELOGS.md',
      'assets/changelogs.md',
    ];
    for (final path in candidates) {
      try {
        final data = await rootBundle.loadString(path);
        debugPrint('[WhatsNew] Loaded changelog from $path');
        return data;
      } catch (_) {
        // Try next candidate
      }
    }
    return null;
  }

  static String? _extractBlock(String changelog, String version) {
    final headingPattern = RegExp(
      '^##\\s+v?${RegExp.escape(version)}\\s*\$',
      multiLine: true,
    );
    final headingMatch = headingPattern.firstMatch(changelog);
    if (headingMatch == null) return null;

    final nextHeadingPattern = RegExp('^##\\s+v', multiLine: true);
    final laterHeadings = nextHeadingPattern
        .allMatches(changelog)
        .where((m) => m.start > headingMatch.start)
        .toList();
    final endIndex = laterHeadings.isNotEmpty
        ? laterHeadings.first.start
        : changelog.length;

    final block = changelog.substring(headingMatch.end, endIndex).trim();
    return block.isEmpty ? null : block;
  }

  static WhatsNewData? _parseBlock(String version, String block) {
    debugPrint('[WhatsNew] Block length=${block.length}');
    final previewEnd = block.length.clamp(0, 200);
    debugPrint('[WhatsNew] Block preview=${block.substring(0, previewEnd)}');

    final lines = const LineSplitter().convert(block);
    debugPrint('[WhatsNew] Line count=${lines.length}');
    final sections = <WhatsNewSection>[];
    String? currentTitle;
    final currentItems = <String>[];

    void pushSection() {
      if ((currentTitle != null && currentItems.isNotEmpty) ||
          (currentTitle == null && currentItems.isNotEmpty)) {
        sections.add(
          WhatsNewSection(
            title: currentTitle ?? 'Changes',
            items: List.unmodifiable(currentItems),
          ),
        );
      }
      currentItems.clear();
    }

    for (final line in lines) {
      if (line.startsWith('### ')) {
        pushSection();
        currentTitle = line.substring(4).trim();
        continue;
      }
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (line.startsWith('- ')) {
        currentItems.add(line.substring(2).trim());
      } else {
        // Treat free text (e.g., intro sentences) as bullet items so they show up.
        currentItems.add(trimmed);
      }
    }
    pushSection();

    if (sections.isNotEmpty) {
      final itemCount = sections.fold<int>(0, (sum, s) => sum + s.items.length);
      debugPrint(
        '[WhatsNew] Parsed version=$version sections=${sections.length} items=$itemCount',
      );
    } else {
      debugPrint('[WhatsNew] Parsed version=$version with no sections/items');
    }

    if (sections.isEmpty) return null;
    return WhatsNewData(version: version, sections: sections);
  }
}
