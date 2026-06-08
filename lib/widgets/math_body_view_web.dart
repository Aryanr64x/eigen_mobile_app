import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

class MathBodyView extends StatefulWidget {
  final String htmlBody;
  const MathBodyView({super.key, required this.htmlBody});

  @override
  State<MathBodyView> createState() => _MathBodyViewState();
}

class _MathBodyViewState extends State<MathBodyView> {
  late final String _viewId;
  double _height = 300;

  @override
  void initState() {
    super.initState();
    _viewId = 'math-body-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = web.HTMLIFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..setAttribute('sandbox', 'allow-scripts allow-same-origin')
      ..srcdoc = _buildHtml(widget.htmlBody).toJS;

      web.window.addEventListener(
        'message',
        (web.MessageEvent event) {
          final data = (event.data.dartify() as Map?);
          if (data != null && data['type'] == 'mathjax-height') {
            final h = (data['height'] as num?)?.toDouble();
            if (h != null && mounted) setState(() => _height = h + 24);
          }
        }.toJS,
      );

      return iframe;
    });
  }

  String _buildHtml(String body) {
    const mathJaxConfig = r"""
      MathJax = {
        tex: {
          inlineMath: [['$', '$'], ['\\(', '\\)']],
          displayMath: [['$$', '$$'], ['\\[', '\\]']]
        },
        svg: { fontCache: 'global' },
        startup: {
          ready() {
            MathJax.startup.defaultReady();
            MathJax.startup.promise.then(() => {
              window.parent.postMessage(
                { type: 'mathjax-height', height: document.body.scrollHeight },
                '*'
              );
            });
          }
        }
      };
    """;
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script>$mathJaxConfig</script>
  <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js"></script>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, sans-serif;
      font-size: 15px;
      line-height: 1.7;
      color: #1a1a1a;
      background: transparent;
      overflow-x: hidden;
    }
    svg { max-width: 100%; height: auto; display: block; margin: 8px auto; }
    mjx-container { overflow-x: auto; max-width: 100%; }
  </style>
</head>
<body>$body</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}