import 'package:flutter/material.dart';

import '../theme.dart';

/// The teal title bar and bordered body that every right-hand box shares.
class GraphPanel extends StatelessWidget {
  const GraphPanel({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.onMinimize,
    this.collapsed = false,
    this.maxBodyHeight = 320,
  });

  final Widget title;
  final Widget child;
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final bool collapsed;
  final double maxBodyHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          height: 30,
          color: GraphColors.accent,
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                  child: title,
                ),
              ),
              if (onMinimize != null)
                _HeaderButton(
                  glyph: collapsed ? '+' : '–',
                  onPressed: onMinimize!,
                ),
              if (onClose != null)
                _HeaderButton(glyph: '✕', onPressed: onClose!),
            ],
          ),
        ),
        if (!collapsed)
          Container(
            constraints: BoxConstraints(maxHeight: maxBodyHeight),
            decoration: BoxDecoration(
              color: GraphColors.panelBackground,
              border: Border.all(color: GraphColors.accent, width: 2),
            ),
            padding: const EdgeInsets.all(12),
            child: Scrollbar(
              child: SingleChildScrollView(child: child),
            ),
          ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.glyph, required this.onPressed});

  final String glyph;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 22,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: 15,
        splashRadius: 14,
        icon: Text(
          glyph,
          style: const TextStyle(color: Colors.black, fontSize: 15),
        ),
      ),
    );
  }
}

/// A flat, outlined button in the original's style.
class GraphButton extends StatelessWidget {
  const GraphButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback onPressed;
  final bool active;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? Colors.black : GraphColors.cardDetail,
        backgroundColor: active
            ? const Color.fromRGBO(0, 255, 255, 0.5)
            : Colors.transparent,
        side: const BorderSide(color: GraphColors.cardDetail),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, letterSpacing: 1)),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// A file name or node reference the user can click to fly to.
class GraphLinkText extends StatelessWidget {
  const GraphLinkText({
    super.key,
    required this.text,
    required this.onTap,
    this.trailing = '',
  });

  final String text;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: text,
                style: const TextStyle(
                  color: Color(0xFFBDBDBD),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFBDBDBD),
                ),
              ),
              if (trailing.isNotEmpty) TextSpan(text: trailing),
            ],
          ),
          style: kMonospace,
        ),
      ),
    );
  }
}
