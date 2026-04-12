import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/teacher_message.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

/// Telegram-style thread: student (`studentId` null) or teacher (`studentId` set).
class TeacherChatScreen extends ConsumerStatefulWidget {
  const TeacherChatScreen({
    super.key,
    this.studentId,
    this.peerTitleHint,
  });

  /// When set, current user is the teacher chatting with this student.
  final int? studentId;

  /// Optional title hint when opening from teacher panel (e.g. student name).
  final String? peerTitleHint;

  @override
  ConsumerState<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends ConsumerState<TeacherChatScreen> {
  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Future<TeacherMessagesThread>? _threadFuture;
  var _didMarkRead = false;
  var _didScheduleScroll = false;
  String? _resolvedPeerTitle;

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  int? get _sid => widget.studentId;

  bool get _isTeacherView => _sid != null;

  Future<TeacherMessagesThread> _fetch() {
    return ref.read(apiServiceProvider).fetchTeacherMessages(studentId: _sid);
  }

  Future<void> _markReadOnce() async {
    if (_didMarkRead) return;
    _didMarkRead = true;
    try {
      await ref.read(apiServiceProvider).markTeacherMessagesRead(studentId: _sid);
      ref.invalidate(teacherMessagesPreviewProvider);
    } catch (_) {}
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo(max);
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    _text.clear();
    FocusScope.of(context).unfocus();
    try {
      await ref.read(apiServiceProvider).sendTeacherMessage(t, studentId: _sid);
      ref.invalidate(teacherMessagesPreviewProvider);
      final next = _fetch();
      if (mounted) {
        setState(() {
          _threadFuture = next;
        });
      }
      await next;
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  String _defaultTitle(AppLocalizations l10n) {
    if (_isTeacherView) {
      return widget.peerTitleHint?.trim().isNotEmpty == true
          ? widget.peerTitleHint!.trim()
          : l10n.teacherStudentChat;
    }
    return l10n.youSectionMessages;
  }

  String _otherSenderLabel(
    AppLocalizations l10n,
    TeacherMessagesThread thread,
  ) {
    if (_isTeacherView) {
      final n = thread.student?.displayName?.trim();
      if (n != null && n.isNotEmpty) return n;
      return l10n.tabStudents;
    }
    final n = thread.teacher?.displayName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return l10n.youSectionMessages;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final myId = ref.watch(authProvider).valueOrNull?.user.id;

    if (_isTeacherView && (_sid == null || _sid! < 1)) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.teacherStudentChat),
        ),
        body: Center(child: Text(l10n.errorGeneric)),
      );
    }

    _threadFuture ??= _fetch();

    final appTitle = _resolvedPeerTitle ?? _defaultTitle(l10n);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(appTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<TeacherMessagesThread>(
              future: _threadFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.errorGeneric),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                _threadFuture = _fetch();
                                _didMarkRead = false;
                                _didScheduleScroll = false;
                              });
                            },
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final thread = snap.data!;
                final peer = _otherSenderLabel(l10n, thread);
                final nameFromApi = _isTeacherView
                    ? thread.student?.displayName?.trim()
                    : thread.teacher?.displayName?.trim();
                if (nameFromApi != null &&
                    nameFromApi.isNotEmpty &&
                    _resolvedPeerTitle != nameFromApi) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() => _resolvedPeerTitle = nameFromApi);
                  });
                }

                if (!_didScheduleScroll && thread.messages.isNotEmpty) {
                  _didScheduleScroll = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await _markReadOnce();
                    _scrollToEnd();
                  });
                } else if (thread.messages.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _markReadOnce();
                  });
                }

                final msgs = thread.messages;

                if (msgs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.teacherMessagesEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final mine = myId != null && m.senderUserId == myId;
                    final showSender = i == 0 ||
                        msgs[i - 1].senderUserId != m.senderUserId;
                    final senderCaption = showSender
                        ? (mine ? l10n.chatSenderYou : peer)
                        : null;
                    return _Bubble(
                      message: m,
                      isMine: mine,
                      scheme: scheme,
                      senderCaption: senderCaption,
                    );
                  },
                );
              },
            ),
          ),
          Material(
            elevation: 3,
            color: scheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: l10n.teacherChatHint,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMine,
    required this.scheme,
    this.senderCaption,
  });

  final TeacherMessageRow message;
  final bool isMine;
  final ColorScheme scheme;
  final String? senderCaption;

  @override
  Widget build(BuildContext context) {
    final bg =
        isMine ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = isMine ? scheme.onPrimaryContainer : scheme.onSurface;
    final align = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final cap = Theme.of(context).textTheme;
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (senderCaption != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 6, right: 6, bottom: 4),
                child: Text(
                  senderCaption!,
                  style: cap.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
              ),
              child: Text(
                message.body,
                style: TextStyle(color: fg, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
