import 'dart:async';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/auth/auth_provider.dart';
import '../../core/profile/profile_avatar.dart';
import '../../data/models/teacher_message.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../teacher/messages_updating.dart';
import '../teacher/teacher_chat_open_args.dart';
import '../teacher/teacher_chat_ui.dart';
import 'chat_text_direction.dart';

/// Telegram-style thread: student (`studentId` null) or teacher (`studentId` set).
class TeacherChatScreen extends ConsumerStatefulWidget {
  const TeacherChatScreen({
    super.key,
    this.studentId,
    this.peerTeacherId,
    this.peerTitleHint,
    this.teacherPeer,
  });

  /// When set, current user is the teacher chatting with this student.
  final int? studentId;

  /// Learner: which staff thread (`teacher_user_id` in API). Required when multiple chats.
  final int? peerTeacherId;

  /// Legacy: title hint when [teacherPeer] is null.
  final String? peerTitleHint;

  /// Rich open args (inbox / student detail): avatar + title.
  final TeacherChatOpenArgs? teacherPeer;

  @override
  ConsumerState<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends ConsumerState<TeacherChatScreen>
    with WidgetsBindingObserver {
  static const _kPollInterval = Duration(seconds: 4);

  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _textFocus = FocusNode();
  Future<TeacherMessagesThread>? _threadFuture;
  var _didMarkRead = false;
  var _didScheduleScroll = false;
  String? _resolvedPeerTitle;
  TeacherMessagesThread? _threadForAppBar;

  Timer? _pollTimer;
  int? _threadFingerprint;

  /// True while the emoji panel is open below the input.
  bool _emojiOpen = false;
  TextDirection _inputDirection = TextDirection.ltr;

  /// The own, still-unread message the user is currently rewriting inline.
  /// When non-null the input area swaps to Telegram-style "edit mode".
  TeacherMessageRow? _editingMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Seed the future through the counter so the AppBar shows "Updating …"
    // even during the very first render.
    _threadFuture = _kickInitialFetch();
    _text.addListener(_handleTextChanged);
    _textFocus.addListener(_handleFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startChatPolling());
  }

  Future<TeacherMessagesThread> _kickInitialFetch() {
    return withMessagesUpdating(ref, _fetch);
  }

  /// Recomputes direction for the input field whenever the user types.
  void _handleTextChanged() {
    final next = detectMessageDirection(_text.text);
    if (next != _inputDirection) {
      setState(() => _inputDirection = next);
    }
  }

  /// Closes the emoji panel automatically when the keyboard opens.
  void _handleFocusChanged() {
    if (_textFocus.hasFocus && _emojiOpen) {
      setState(() => _emojiOpen = false);
    }
  }

  Future<void> _toggleEmojiPanel() async {
    if (_emojiOpen) {
      setState(() => _emojiOpen = false);
      _textFocus.requestFocus();
      return;
    }
    // Dismiss keyboard first so the emoji grid has room to display.
    if (_textFocus.hasFocus) {
      _textFocus.unfocus();
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    if (!mounted) return;
    setState(() => _emojiOpen = true);
  }

  void _insertEmoji(Emoji emoji) {
    final selection = _text.selection;
    final text = _text.text;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, emoji.emoji);
    final caret = start + emoji.emoji.length;
    _text.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret),
      composing: TextRange.empty,
    );
  }

  void _onEmojiBackspace() {
    final selection = _text.selection;
    final text = _text.text;
    if (text.isEmpty) return;
    // Remove one grapheme (an emoji can be multi-code-unit) from the caret.
    final end = selection.isValid && selection.end > 0
        ? selection.end
        : text.length;
    final chars = text.substring(0, end).characters;
    if (chars.isEmpty) return;
    final removed = chars.skipLast(1).toString();
    final tail = text.substring(end);
    final newText = removed + tail;
    _text.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: removed.length),
      composing: TextRange.empty,
    );
  }

  @override
  void dispose() {
    _stopChatPolling();
    WidgetsBinding.instance.removeObserver(this);
    _text
      ..removeListener(_handleTextChanged)
      ..dispose();
    _textFocus
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startChatPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopChatPolling();
    }
  }

  void _startChatPolling() {
    if (!mounted) return;
    _pollTimer?.cancel();
    unawaited(_pollThread());
    _pollTimer = Timer.periodic(_kPollInterval, (_) => _pollThread());
  }

  void _stopChatPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Changes when messages are added/removed (not live WebSocket — polling).
  int _fingerprint(TeacherMessagesThread t) {
    if (t.messages.isEmpty) return 0;
    final last = t.messages.last;
    return Object.hash(t.messages.length, last.id);
  }

  Future<void> _pollThread() async {
    if (!mounted) return;
    await withMessagesUpdating(ref, () async {
      try {
        final next = await _fetch();
        if (!mounted) return;
        final fp = _fingerprint(next);
        if (_threadFingerprint != fp) {
          setState(() {
            _threadFingerprint = fp;
            _threadFuture = Future.value(next);
          });
          try {
            await ref.read(apiServiceProvider).markTeacherMessagesRead(
                  studentId: _sid,
                  peerTeacherId: _isTeacherView ? null : widget.peerTeacherId,
                );
          } catch (_) {}
          if (!mounted) return;
          ref.invalidate(teacherMessagesPreviewProvider);
          ref.invalidate(teacherMessagesUnreadFabProvider);
          ref.invalidate(teacherInboxStudentsProvider);
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
        }
      } catch (_) {}
    });
  }

  int? get _sid => widget.studentId;

  bool get _isTeacherView => _sid != null;

  Future<TeacherMessagesThread> _fetch() {
    return ref.read(apiServiceProvider).fetchTeacherMessages(
          studentId: _sid,
          peerTeacherId: _isTeacherView ? null : widget.peerTeacherId,
        );
  }

  Future<void> _markReadOnce() async {
    if (_didMarkRead) return;
    _didMarkRead = true;
    try {
      await ref.read(apiServiceProvider).markTeacherMessagesRead(
            studentId: _sid,
            peerTeacherId: _isTeacherView ? null : widget.peerTeacherId,
          );
      ref.invalidate(teacherMessagesPreviewProvider);
      ref.invalidate(teacherMessagesUnreadFabProvider);
      ref.invalidate(teacherInboxStudentsProvider);
    } catch (_) {}
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo(max);
  }

  Future<void> _send() async {
    // In inline edit mode, reuse the composer to save the edit instead.
    if (_editingMessage != null) {
      await _saveInlineEdit();
      return;
    }
    final t = _text.text.trim();
    if (t.isEmpty) return;
    _text.clear();
    FocusScope.of(context).unfocus();
    try {
      await ref.read(apiServiceProvider).sendTeacherMessage(
            t,
            studentId: _sid,
            peerTeacherId: _isTeacherView ? null : widget.peerTeacherId,
          );
      ref.invalidate(teacherMessagesPreviewProvider);
      ref.invalidate(teacherMessagesUnreadFabProvider);
      ref.invalidate(teacherInboxStudentsProvider);
      final next = _fetch();
      if (mounted) {
        setState(() {
          _threadFuture = next;
        });
      }
      final thread = await next;
      if (mounted) {
        _threadFingerprint = _fingerprint(thread);
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

  Future<void> _onMessageLongPress(TeacherMessageRow m) async {
    // Only the sender can edit, and only while the other side hasn't read it.
    final myId = ref.read(authProvider).valueOrNull?.user.id;
    if (myId == null || m.senderUserId != myId || m.isRead) return;

    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_rounded, color: scheme.primary),
              title: Text(l10n.chatMessageEdit),
              onTap: () => Navigator.of(ctx).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: Text(l10n.cancel),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action != 'edit') return;
    _startInlineEdit(m);
  }

  /// Swaps the composer into Telegram-style inline edit mode: pre-fills the
  /// text field with the existing body, closes the emoji panel, focuses the
  /// field and shows the "Edit message" banner above it.
  void _startInlineEdit(TeacherMessageRow m) {
    _text.value = TextEditingValue(
      text: m.body,
      selection: TextSelection.collapsed(offset: m.body.length),
    );
    setState(() {
      _editingMessage = m;
      _emojiOpen = false;
    });
    // Let the setState settle before we steal focus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _textFocus.requestFocus();
    });
  }

  /// Cancels edit mode without saving. Leaves the text field empty, just like
  /// tapping the × on Telegram's edit banner does.
  void _cancelInlineEdit() {
    if (_editingMessage == null) return;
    _text.clear();
    setState(() => _editingMessage = null);
  }

  /// Persists the inline edit. Preserves edit mode only when the save fails
  /// for a reason that's worth retrying; otherwise clears the banner.
  Future<void> _saveInlineEdit() async {
    final target = _editingMessage;
    if (target == null) return;
    final l10n = AppLocalizations.of(context)!;
    final trimmed = _text.text.trim();

    // No-op changes just leave edit mode cleanly.
    if (trimmed.isEmpty || trimmed == target.body) {
      _cancelInlineEdit();
      return;
    }

    try {
      await ref.read(apiServiceProvider).editTeacherMessage(
            messageId: target.id,
            newBody: trimmed,
          );
      if (!mounted) return;
      _text.clear();
      setState(() => _editingMessage = null);
      FocusScope.of(context).unfocus();
      final next = _fetch();
      setState(() {
        _threadFuture = next;
        _threadFingerprint = null;
      });
      await next;
      ref.invalidate(teacherMessagesPreviewProvider);
      ref.invalidate(teacherInboxStudentsProvider);
    } on TeacherMessageAlreadyReadException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatMessageEditFailedRead)),
      );
      // Recipient read it in the meantime — exit edit mode and refresh ticks.
      _text.clear();
      setState(() => _editingMessage = null);
      final next = _fetch();
      setState(() => _threadFuture = next);
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
      return widget.teacherPeer?.displayTitle ??
          (widget.peerTitleHint?.trim().isNotEmpty == true
              ? widget.peerTitleHint!.trim()
              : l10n.teacherStudentChat);
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

  Widget _buildSubtitle(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme scheme,
    String fallback, {
    required bool updating,
  }) {
    final tt = Theme.of(context).textTheme;
    if (updating) {
      return Padding(
        padding: const EdgeInsets.only(top: 1),
        child: MessagesUpdatingLabel(
          active: true,
          color: scheme.primary,
          style: tt.labelSmall,
        ),
      );
    }
    return Text(
      fallback,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: tt.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget? _appBarTitleWidget(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme scheme, {
    required bool updating,
  }) {
    final tt = Theme.of(context).textTheme;
    if (_isTeacherView) {
      final p = widget.teacherPeer;
      final title = _resolvedPeerTitle ??
          p?.displayTitle ??
          _defaultTitle(l10n);
      if (p != null) {
        return Row(
          children: [
            ProfileAvatar(
              avatarId: p.avatarId,
              userId: p.userId,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  _buildSubtitle(
                    context,
                    l10n,
                    scheme,
                    l10n.tabStudents,
                    updating: updating,
                  ),
                ],
              ),
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          if (updating)
            MessagesUpdatingLabel(
              active: true,
              color: scheme.primary,
              style: tt.labelSmall,
            ),
        ],
      );
    }

    final thread = _threadForAppBar;
    final tid = thread?.teacher?.id;
    final tname = thread?.teacher?.displayName?.trim();
    if (tid != null) {
      return Row(
        children: [
          ProfileAvatar(
            avatarId: 'm1',
            userId: tid,
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (tname != null && tname.isNotEmpty)
                      ? tname
                      : l10n.youSectionMessages,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                _buildSubtitle(
                  context,
                  l10n,
                  scheme,
                  l10n.youSectionMessagesSubtitle,
                  updating: updating,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _defaultTitle(l10n),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (updating)
          MessagesUpdatingLabel(
            active: true,
            color: scheme.primary,
            style: tt.labelSmall,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final myId = ref.watch(authProvider).valueOrNull?.user.id;
    final updating = ref.watch(messagesUpdatingProvider);

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

    _threadFuture ??= _kickInitialFetch();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: _appBarTitleWidget(context, l10n, scheme, updating: updating),
      ),
      body: DecoratedBox(
        decoration: TeacherChatUi.screenBackground(scheme),
        child: Column(
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
                                  _threadFingerprint = null;
                                  _didMarkRead = false;
                                  _didScheduleScroll = false;
                                  _threadForAppBar = null;
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
                  _threadFingerprint ??= _fingerprint(thread);
                  if (!identical(_threadForAppBar, thread)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _threadForAppBar = thread);
                    });
                  }

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
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 20),
                    itemCount: msgs.length,
                    itemBuilder: (context, i) {
                      final m = msgs[i];
                      final mine = myId != null && m.senderUserId == myId;
                      final showSender = i == 0 ||
                          msgs[i - 1].senderUserId != m.senderUserId;
                      final senderCaption = showSender
                          ? (mine ? l10n.chatSenderYou : _otherSenderLabel(l10n, thread))
                          : null;
                      final localeName = Localizations.localeOf(context).toLanguageTag();
                      final dt = TeacherChatUi.tryParseApiDate(m.createdAt);
                      final prevDt = i > 0
                          ? TeacherChatUi.tryParseApiDate(msgs[i - 1].createdAt)
                          : null;
                      final showDayHeader = i == 0 ||
                          (dt != null && (prevDt == null || !_sameDay(dt, prevDt)));

                      final canEdit = mine && !m.isRead;
                      final bubble = _Bubble(
                        message: m,
                        isMine: mine,
                        scheme: scheme,
                        senderCaption: senderCaption,
                        timestampLocal: dt,
                        localeName: localeName,
                        onLongPress: canEdit ? () => _onMessageLongPress(m) : null,
                      );

                      if (!showDayHeader) return bubble;
                      return Column(
                        children: [
                          _DaySeparator(
                            dateLocal: dt,
                            localeName: localeName,
                          ),
                          bubble,
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Material(
              elevation: 6,
              shadowColor: Colors.black26,
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.95),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.bottomCenter,
                      child: _editingMessage == null
                          ? const SizedBox(height: 0, width: double.infinity)
                          : _EditBanner(
                              preview: _editingMessage!.body,
                              onCancel: _cancelInlineEdit,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: _emojiOpen
                                ? l10n.close
                                : l10n.teacherChatHint,
                            onPressed: _toggleEmojiPanel,
                            icon: Icon(
                              _emojiOpen
                                  ? Icons.keyboard_rounded
                                  : Icons.emoji_emotions_outlined,
                              color: scheme.primary,
                              size: 26,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _text,
                              focusNode: _textFocus,
                              minLines: 1,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              textDirection: _inputDirection,
                              decoration: InputDecoration(
                                hintText: _editingMessage != null
                                    ? l10n.chatMessageEditHint
                                    : l10n.teacherChatHint,
                                filled: true,
                                fillColor: scheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(26),
                                  borderSide: BorderSide(
                                    color: scheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(26),
                                  borderSide: BorderSide(
                                    color: scheme.outlineVariant
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(26),
                                  borderSide: BorderSide(
                                    color: scheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                              onTap: () {
                                if (_emojiOpen) {
                                  setState(() => _emojiOpen = false);
                                }
                              },
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: _editingMessage != null
                                ? l10n.chatMessageEditSave
                                : null,
                            style: IconButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                            ),
                            onPressed: _send,
                            icon: Icon(
                              _editingMessage != null
                                  ? Icons.check_rounded
                                  : Icons.send_rounded,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: _emojiOpen
                          ? _EmojiPanel(
                              onEmojiSelected: (_, emoji) =>
                                  _insertEmoji(emoji),
                              onBackspacePressed: _onEmojiBackspace,
                            )
                          : const SizedBox(height: 0, width: double.infinity),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMine,
    required this.scheme,
    required this.localeName,
    this.timestampLocal,
    this.senderCaption,
    this.onLongPress,
  });

  final TeacherMessageRow message;
  final bool isMine;
  final ColorScheme scheme;
  final String localeName;
  final DateTime? timestampLocal;
  final String? senderCaption;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bg = isMine
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final fg = isMine ? scheme.onPrimaryContainer : scheme.onSurface;
    final align = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final cap = Theme.of(context).textTheme;
    final footerColor = fg.withValues(alpha: 0.75);

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.84,
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
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
            Material(
              elevation: isMine ? 0.5 : 0.8,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMine ? 20 : 5),
                bottomRight: Radius.circular(isMine ? 5 : 20),
              ),
              color: bg,
              child: InkWell(
                onLongPress: onLongPress,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMine ? 20 : 5),
                  bottomRight: Radius.circular(isMine ? 5 : 20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: detectMessageDirection(message.body),
                        child: Text(
                          message.body,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: fg,
                            height: 1.38,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: isMine
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (message.isEdited) ...[
                            Text(
                              l10n.chatMessageEdited,
                              style: cap.labelSmall?.copyWith(
                                color: footerColor,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (timestampLocal != null)
                            Text(
                              DateFormat.jm(localeName)
                                  .format(timestampLocal!),
                              style: cap.labelSmall?.copyWith(
                                color: footerColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (isMine) ...[
                            const SizedBox(width: 4),
                            _ReadReceiptTicks(
                              isRead: message.isRead,
                              color: footerColor,
                              readColor: scheme.primary,
                              sentLabel: l10n.chatMessageReadStateSent,
                              readLabel: l10n.chatMessageReadStateRead,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Telegram-style delivery indicator: one tick = sent, two ticks (highlighted)
/// = read by the recipient.
class _ReadReceiptTicks extends StatelessWidget {
  const _ReadReceiptTicks({
    required this.isRead,
    required this.color,
    required this.readColor,
    required this.sentLabel,
    required this.readLabel,
  });

  final bool isRead;
  final Color color;
  final Color readColor;
  final String sentLabel;
  final String readLabel;

  @override
  Widget build(BuildContext context) {
    const double size = 16;
    final tint = isRead ? readColor : color;
    return Tooltip(
      message: isRead ? readLabel : sentLabel,
      child: Semantics(
        label: isRead ? readLabel : sentLabel,
        child: Icon(
          isRead ? Icons.done_all_rounded : Icons.check_rounded,
          size: size,
          color: tint,
        ),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({
    required this.dateLocal,
    required this.localeName,
  });

  final DateTime? dateLocal;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    if (dateLocal == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final label = DateFormat.yMMMMd(localeName).format(dateLocal!);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

/// Telegram-style edit banner pinned above the text field.
///
/// Shows a vertical accent stripe, a pencil + "Edit message" label, a single
/// line preview of the original body, and a close button on the trailing edge.
/// Tapping the close button cancels edit mode without touching the server.
class _EditBanner extends StatelessWidget {
  const _EditBanner({required this.preview, required this.onCancel});

  /// The current body of the message being edited (used as the preview line).
  final String preview;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 6, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Accent stripe, exactly like Telegram's reply/edit indicator.
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.edit_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.chatMessageEditTitle,
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                // Preview respects Persian / Arabic content without flipping
                // the banner itself.
                Directionality(
                  textDirection: detectMessageDirection(preview),
                  child: Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.cancel,
            onPressed: onCancel,
            icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Emoji picker shown below the text field when the user taps the smiley.
///
/// We let the picker size itself to a fraction of the screen so it feels like
/// a soft keyboard without stealing real-estate on tiny devices.
class _EmojiPanel extends StatelessWidget {
  const _EmojiPanel({
    required this.onEmojiSelected,
    required this.onBackspacePressed,
  });

  final void Function(Category?, Emoji) onEmojiSelected;
  final VoidCallback onBackspacePressed;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Aim for roughly the height of a keyboard; clamp to sensible limits for
    // short screens and tablets so the grid stays usable everywhere.
    final height = (media.size.height * 0.35).clamp(250.0, 320.0).toDouble();
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: EmojiPicker(
        onEmojiSelected: onEmojiSelected,
        onBackspacePressed: onBackspacePressed,
        config: Config(
          height: height,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            columns: 8,
            emojiSizeMax: 28 * (media.size.shortestSide >= 600 ? 1.10 : 1.0),
            backgroundColor: scheme.surface,
            verticalSpacing: 2,
            horizontalSpacing: 2,
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: scheme.surfaceContainerHigh,
            indicatorColor: scheme.primary,
            iconColor: scheme.onSurfaceVariant,
            iconColorSelected: scheme.primary,
            tabIndicatorAnimDuration: kTabScrollDuration,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            backgroundColor: scheme.surfaceContainerHigh,
            buttonColor: scheme.surfaceContainerHighest,
            buttonIconColor: scheme.onSurfaceVariant,
            showBackspaceButton: true,
            showSearchViewButton: true,
          ),
          searchViewConfig: SearchViewConfig(
            backgroundColor: scheme.surfaceContainerHigh,
            buttonIconColor: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
