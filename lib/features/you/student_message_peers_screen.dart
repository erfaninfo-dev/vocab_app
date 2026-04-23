import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../data/models/teacher_message.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../teacher/messages_updating.dart';

/// Learner: choose which teacher/admin thread to open.
class StudentMessagePeersScreen extends ConsumerStatefulWidget {
  const StudentMessagePeersScreen({super.key});

  @override
  ConsumerState<StudentMessagePeersScreen> createState() =>
      _StudentMessagePeersScreenState();
}

class _StudentMessagePeersScreenState
    extends ConsumerState<StudentMessagePeersScreen>
    with WidgetsBindingObserver {
  static const _kPollInterval = Duration(seconds: 15);

  Future<List<StudentMessagePeerRow>>? _future;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _future = _loadPeers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPolling());
  }

  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = startMessagesPolling(
      interval: _kPollInterval,
      runImmediately: false,
      tick: _refresh,
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<List<StudentMessagePeerRow>> _loadPeers() {
    return withMessagesUpdating(
      ref,
      () => ref.read(apiServiceProvider).fetchStudentMessagePeers(),
    );
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final next = _loadPeers();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final updating = ref.watch(messagesUpdatingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.youMessagesPickTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (updating)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: MessagesUpdatingLabel(
                  active: true,
                  color: scheme.primary,
                  style: tt.labelSmall,
                ),
              ),
          ],
        ),
        backgroundColor: scheme.surface,
      ),
      body: RefreshIndicator(
        color: scheme.primary,
        onRefresh: _refresh,
        child: FutureBuilder<List<StudentMessagePeerRow>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return Center(
                child: CircularProgressIndicator(color: scheme.primary),
              );
            }
            if (snap.hasError && !snap.hasData) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    userFriendlyErrorMessage(snap.error!, l10n),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final peers = snap.data ?? const <StudentMessagePeerRow>[];
            if (peers.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.teacherMessagesEmpty,
                      textAlign: TextAlign.center,
                      style: tt.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: peers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = peers[i];
                final name = p.displayName?.trim().isNotEmpty == true
                    ? p.displayName!.trim()
                    : l10n.youSectionMessages;
                String? timeStr;
                final raw = p.lastMessageAt;
                if (raw != null && raw.trim().isNotEmpty) {
                  final dt = DateTime.tryParse(
                    raw.contains('T') ? raw : raw.replaceFirst(' ', 'T'),
                  );
                  if (dt != null) {
                    timeStr = DateFormat.yMMMd(locale)
                        .add_jm()
                        .format(dt.toLocal());
                  }
                }
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        Icons.person_rounded,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      name,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: timeStr != null
                        ? Text(timeStr, style: tt.bodySmall)
                        : null,
                    trailing: p.unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.error,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              p.unreadCount > 99 ? '99+' : '${p.unreadCount}',
                              style: TextStyle(
                                color: scheme.onError,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.chevron_right_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                    onTap: () {
                      context.push(
                        '/you/messages?peer_teacher_id=${p.teacherUserId}',
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
