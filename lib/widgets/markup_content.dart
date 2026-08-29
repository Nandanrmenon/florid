import 'package:material_ui/material_ui.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class MarkupContent extends StatelessWidget {
  final String? data;
  final bool shrinkWrap;
  final TextStyle? textStyle;

  const MarkupContent({
    super.key,
    required this.data,
    this.shrinkWrap = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final content = data?.trim();
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    return HtmlWidget(
      md.markdownToHtml(content, extensionSet: md.ExtensionSet.gitHubWeb),
      textStyle: textStyle,
      onTapUrl: (url) async {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          await launchUrl(uri);
          return true;
        }
        return false;
      },
    );
  }
}