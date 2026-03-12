import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class MarkupContent extends StatelessWidget {
  final String? data;
  final bool shrinkWrap;
  final Map<String, Style> style;

  const MarkupContent({
    super.key,
    required this.data,
    this.shrinkWrap = false,
    this.style = const <String, Style>{},
  });

  @override
  Widget build(BuildContext context) {
    final content = data?.trim();
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Html(
      data: md.markdownToHtml(content, extensionSet: md.ExtensionSet.gitHubWeb),
      shrinkWrap: shrinkWrap,
      style: style,
      onLinkTap: (url, attributes, element) {
        final uri = url != null ? Uri.tryParse(url) : null;
        if (uri != null) {
          launchUrl(uri);
        }
      },
    );
  }
}
