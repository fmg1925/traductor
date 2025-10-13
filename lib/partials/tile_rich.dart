import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:traductor/pages/home.dart' show tts;
import '../l10n/app_localizations.dart';

class TileRich extends StatelessWidget {
  const TileRich({
    super.key,
    required this.title,
    required this.body,
    this.color,
    this.errorText,
    this.onTts,
    this.copyText,
    this.buttons,
    this.speaking,
    this.isSpeaking = false,
    this.wrapper,
  });

  final String title;
  final Widget body;

  final Color? color;

  final String? errorText;

  final VoidCallback? onTts;

  final String? copyText;

  final Widget? buttons;

  final ValueListenable<bool>? speaking;

  final bool isSpeaking;

  final Widget Function(Widget child)? wrapper;

  static const double _railW = 48.0;
  static const double _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final showDefaultActions =
        (onTts != null && copyText != null && buttons == null);
    final hasRail = buttons != null || showDefaultActions;

    Widget? rail = buttons;

    if (rail == null && showDefaultActions) {
      Widget micButton(bool speakingNow) {
        return IconButton.filledTonal(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              speakingNow ? Icons.stop : Icons.volume_up,
              key: ValueKey<bool>(speakingNow),
            ),
          ),
          tooltip: speakingNow ? t.stop : t.listen,
          onPressed: onTts,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(
            width: _railW,
            height: _railW,
          ),
          visualDensity: VisualDensity.compact,
        );
      }

      final mic = (speaking != null)
          ? ValueListenableBuilder<bool>(
              valueListenable: speaking!,
              builder: (_, v, _) => micButton(v),
            )
          : micButton(isSpeaking);

      rail = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          mic,
          const SizedBox(height: 8),
          IconButton.filledTonal(
            icon: const Icon(Icons.copy_all),
            tooltip: t.copy,
            onPressed: copyText == null
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: copyText!));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(t.copied)));
                  },
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: _railW,
              height: _railW,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      );
    }

    final content = Container(
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    height: 1.05,
                    color: theme.colorScheme.onPrimary,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: true,
                    applyHeightToLastDescent: false,
                  ),
                ),
                const SizedBox(height: _gap),
                body,
                if (errorText != null) ...[
                  const SizedBox(height: _gap),
                  Text(errorText!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),

          if (hasRail) ...[
            const SizedBox(width: _gap),
            SizedBox(width: _railW, child: rail),
          ],
        ],
      ),
    );

    return wrapper != null ? wrapper!(content) : content;
  }
}

Positioned rightButtons(
    AppLocalizations t,
    VoidCallback onTts,
    String copyText,
    BuildContext context,
  ) {
    return Positioned(
      top: -5,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton.filledTonal(
            icon: Icon(tts.getState() ? Icons.stop : Icons.volume_up),
            tooltip: tts.getState() ? t.stop : t.listen,
            onPressed: onTts,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 50, height: 50),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: 4),
          IconButton.filledTonal(
            icon: const Icon(Icons.copy_all),
            tooltip: t.copy,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: copyText));
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(t.copied)));
            },
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 50, height: 50),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget maxWidth({required Widget child}) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      ),
    ),
  );