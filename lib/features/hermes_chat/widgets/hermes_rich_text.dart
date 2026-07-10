import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

typedef HermesUriLauncher = Future<bool> Function(Uri uri);

/// Selectable GitHub-flavored Markdown used for Hermes-authored transcript text.
class HermesRichText extends StatelessWidget {
  const HermesRichText(this.data, {this.launchUri, super.key});

  final String data;
  final HermesUriLauncher? launchUri;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: MarkdownBody(
        data: data,
        shrinkWrap: true,
        builders: {'pre': _HermesCodeBlockBuilder()},
        imageBuilder: (uri, title, alt) => Text(
          '${(alt == null || alt.trim().isEmpty) ? 'Image' : alt.trim()} '
          '(image not loaded)',
        ),
        onTapLink: (text, href, title) {
          final uri = href == null ? null : Uri.tryParse(href);
          if (uri == null ||
              !_safeLinkSchemes.contains(uri.scheme.toLowerCase())) {
            return;
          }
          unawaited((launchUri ?? _launchUri)(uri));
        },
      ),
    );
  }
}

const _safeLinkSchemes = {'http', 'https', 'mailto'};

Future<bool> _launchUri(Uri uri) => launchUrl(uri);

class _HermesCodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent.replaceFirst(RegExp(r'\n$'), '');
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              key: const ValueKey('hermes-code-copy'),
              tooltip: 'Copy code',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_outlined, size: 18),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!context.mounted) return;
                ScaffoldMessenger.maybeOf(
                  context,
                )?.showSnackBar(const SnackBar(content: Text('Code copied')));
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SelectableText(code, style: preferredStyle),
          ),
        ],
      ),
    );
  }
}
