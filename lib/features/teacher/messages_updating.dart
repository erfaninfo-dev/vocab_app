import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';

/// Concurrent refresh counter shared by the inbox list, peer picker, and the
/// chat thread. Any async refresh bumps the counter so the in-app bar can show
/// a Telegram-style "Updating …" label until every in-flight request finishes.
final messagesUpdatingCountProvider = StateProvider<int>((ref) => 0);

/// True while at least one chat-related refresh is in flight.
final messagesUpdatingProvider = Provider<bool>(
  (ref) => ref.watch(messagesUpdatingCountProvider) > 0,
);

/// Minimum duration a refresh must run before the shared indicator is shown.
///
/// Fast polls (typical case: a few hundred ms on good networks) finish before
/// this timer fires, so the "Updating …" label never appears for them. This
/// mirrors Telegram's behavior — the label only surfaces when there's an
/// actual noticeable delay.
const Duration kMessagesUpdatingShowAfter = Duration(milliseconds: 600);

/// Wraps [task] so the shared counter is incremented while it runs, but only
/// after [showAfter] elapses. Fast refreshes leave the indicator untouched.
///
/// Safe to nest; each invocation owns its own bump/unbump.
/// Accepts either `WidgetRef` (inside widgets) or `Ref` (inside providers)
/// because both expose `.read` with the same semantics.
Future<T> withMessagesUpdating<T>(
  Object ref,
  Future<T> Function() task, {
  Duration showAfter = kMessagesUpdatingShowAfter,
}) async {
  final notifier = _updatingNotifier(ref);
  var bumped = false;
  final delay = Timer(showAfter, () {
    bumped = true;
    notifier.update((v) => v + 1);
  });
  try {
    return await task();
  } finally {
    delay.cancel();
    if (bumped) {
      notifier.update((v) => v > 0 ? v - 1 : 0);
    }
  }
}

StateController<int> _updatingNotifier(Object ref) {
  if (ref is WidgetRef) {
    return ref.read(messagesUpdatingCountProvider.notifier);
  }
  if (ref is Ref) {
    return ref.read(messagesUpdatingCountProvider.notifier);
  }
  throw ArgumentError(
    'withMessagesUpdating expects a WidgetRef or Ref, got ${ref.runtimeType}.',
  );
}

/// "Updating …" with three animated dots; intended for the chat app bar.
///
/// Animates only while [active] is true, pauses otherwise to save frames.
class MessagesUpdatingLabel extends StatefulWidget {
  const MessagesUpdatingLabel({
    super.key,
    required this.active,
    this.style,
    this.color,
  });

  final bool active;
  final TextStyle? style;
  final Color? color;

  @override
  State<MessagesUpdatingLabel> createState() => _MessagesUpdatingLabelState();
}

class _MessagesUpdatingLabelState extends State<MessagesUpdatingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant MessagesUpdatingLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    // Strip a trailing ellipsis from the base label so we can animate dots.
    final raw = l10n.updating;
    final base = raw.replaceAll('…', '').replaceAll('...', '').trimRight();
    final scheme = Theme.of(context).colorScheme;
    final effectiveStyle = (widget.style ??
            Theme.of(context).textTheme.labelSmall)
        ?.copyWith(
      color: widget.color ?? scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final phase = (_ctrl.value * 3).floor() % 3; // 0, 1, 2
        final dots = '.' * (phase + 1);
        return Text(
          '$base $dots',
          style: effectiveStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// Runs [tick] every [interval]; stops when the widget is removed.
///
/// Use inside a `StatefulWidget.initState()`:
/// ```dart
/// _timer = startMessagesPolling(interval: const Duration(seconds: 12), tick: _refreshInbox);
/// ```
Timer startMessagesPolling({
  required Duration interval,
  required Future<void> Function() tick,
  bool runImmediately = true,
}) {
  if (runImmediately) {
    // ignore: discarded_futures
    tick();
  }
  return Timer.periodic(interval, (_) {
    // ignore: discarded_futures
    tick();
  });
}
