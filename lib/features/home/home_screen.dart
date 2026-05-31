import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/branding/app_brand_logo.dart';
import '../../core/errors/user_friendly_error.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/book_model.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../stories/story_providers.dart';
import '../stories/story_ring.dart';
import '../../l10n/app_localizations.dart';
import 'home_book_card.dart';
import 'home_book_track_provider.dart';
import 'home_displayed_books_provider.dart';
import 'series_books_screen.dart';

const Color _kHomeFabHappyBlue = Color(0xFF2196F3);

/// IELTS / General / Students — third segment hidden until re-enabled.
bool homeShowStudentTab(AuthUser? user) {
  return false;
}

int homePageIndexForTrack(HomeBookTrack track, bool showStudentTab) {
  switch (track) {
    case HomeBookTrack.ielts:
      return 0;
    case HomeBookTrack.general:
      return 1;
    case HomeBookTrack.student:
      return showStudentTab ? 2 : 0;
  }
}

HomeBookTrack homeTrackForPageIndex(int index, bool showStudentTab) {
  if (!showStudentTab) {
    return index <= 0 ? HomeBookTrack.ielts : HomeBookTrack.general;
  }
  switch (index) {
    case 0:
      return HomeBookTrack.ielts;
    case 1:
      return HomeBookTrack.general;
    default:
      return HomeBookTrack.student;
  }
}

final searchControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  controller.addListener(() {
    ref.read(bookSearchQueryProvider.notifier).state = controller.text;
  });
  ref.onDispose(() => controller.dispose());
  return controller;
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  Timer? _messageBadgeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPageToTrack());
    _messageBadgeTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      ref.invalidate(teacherMessagesUnreadFabProvider);
      ref.invalidate(teacherInboxStudentsProvider);
    });
  }

  void _syncPageToTrack() {
    if (!mounted) return;
    final showStudent = homeShowStudentTab(
      ref.read(authProvider).valueOrNull?.user,
    );
    final track = ref.read(homeBookTrackProvider);
    final idx = homePageIndexForTrack(track, showStudent);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(idx);
    }
  }

  Future<void> _onRefresh() async {
    await refreshAllRemoteApiData(ref);
    await Future.wait([
      ref.read(apiPublicBooksForHomeProvider.future),
      ref.read(apiStudentBooksForHomeProvider.future),
      ref.read(teacherMessagesUnreadFabProvider.future),
      ref.read(teacherInboxStudentsProvider.future),
    ]);
  }

  Future<void> _onHomePageChanged(int index) async {
    final showStudent = homeShowStudentTab(
      ref.read(authProvider).valueOrNull?.user,
    );
    final track = homeTrackForPageIndex(index, showStudent);
    ref.read(homeBookTrackProvider.notifier).state = track;
    final p = await SharedPreferences.getInstance();
    await p.setString(kHomeBookTrackPrefsKey, track.name);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(reloadBooksCatalogFromNetwork(ref));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageBadgeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showStudent = homeShowStudentTab(
      ref.watch(authProvider).valueOrNull?.user,
    );

    ref.listen(authProvider, (prev, next) {
      if (homeShowStudentTab(next.valueOrNull?.user)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_pageController.hasClients) return;
        if ((_pageController.page ?? 0) >= 2) {
          _pageController.jumpToPage(0);
        }
      });
    });

    final session = ref.watch(authProvider).valueOrNull;
    final user = session?.user;
    final showMessageFab =
        user != null &&
        (user.isTeacher || user.isAdmin || user.teacherUserId != null);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _HomeFloatingActions(
        showMessageFab: showMessageFab,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.10),
              scheme.secondary.withValues(alpha: 0.06),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: const _HomeHeader(),
              ),
              _HomeTrackSegment(pageController: _pageController),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onHomePageChanged,
                  children: [
                    _HomeTrackBookPage(
                      track: HomeBookTrack.ielts,
                      onRefresh: _onRefresh,
                    ),
                    _HomeTrackBookPage(
                      track: HomeBookTrack.general,
                      onRefresh: _onRefresh,
                    ),
                    if (showStudent)
                      _HomeTrackBookPage(
                        track: HomeBookTrack.student,
                        onRefresh: _onRefresh,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTrackBookPage extends ConsumerWidget {
  const _HomeTrackBookPage({required this.track, required this.onRefresh});

  final HomeBookTrack track;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final booksValue = ref.watch(homeDisplayedBooksForTrackProvider(track));

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          booksValue.when(
            loading: () => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        l10n.homeReceivingBooks,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: _HomeBooksErrorState(
                message: userFriendlyErrorMessage(error, l10n),
                onRetry: () {
                  if (track.isStudentCatalog) {
                    ref.invalidate(apiStudentBooksForHomeProvider);
                  } else {
                    ref.invalidate(apiPublicBooksForHomeProvider);
                  }
                },
              ),
            ),
            data: (books) {
              if (books.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Center(
                      child: Text(
                        l10n.noBooksFound,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                );
              }

              return SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 1100
                        ? 3
                        : width >= 700
                        ? 2
                        : 1;

                    final entries = _trackHomeEntriesForTrack(books);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: crossAxisCount == 1
                                        ? 2.15
                                        : 1.42,
                                  ),
                              itemCount: entries.length,
                              itemBuilder: (context, i) {
                                final e = entries[i];
                                if (e.isSeries) {
                                  final seriesTitle =
                                      (e.books!.first.seriesTitle ?? '').trim();
                                  return _IeltsSeriesCard(
                                    title: seriesTitle,
                                    bookCount: e.books!.length,
                                    index: i,
                                    onTap: () {
                                      final sorted = List<Book>.of(e.books!);
                                      sortBooksInSeriesDisplayOrder(sorted);
                                      context.push(
                                        '/series-books',
                                        extra: SeriesBooksRouteArgs(
                                          title: seriesTitle,
                                          books: sorted,
                                        ),
                                      );
                                    },
                                  );
                                }
                                return HomeBookCard(
                                  book: e.book!,
                                  index: i,
                                  onTap: () => context.push(
                                    '/books/${e.book!.id}/units',
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            skipLoadingOnReload: true,
          ),
        ],
      ),
    );
  }
}

class _HomeBooksErrorState extends StatelessWidget {
  const _HomeBooksErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.42),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.errorContainer,
                              scheme.primaryContainer.withValues(alpha: 0.72),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        '📡',
                        style: theme.textTheme.displaySmall,
                        semanticsLabel: l10n.errNoInternet,
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: scheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.wifi_off_rounded,
                            size: 20,
                            color: scheme.onError,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.couldNotLoadBooks,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────── Header ─────────────────────

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final track = ref.watch(homeBookTrackProvider);
    final bookCount = ref.watch(
      homeDisplayedBooksProvider.select((v) => v.valueOrNull?.length ?? 0),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: scheme.surface.withValues(alpha: 0.58),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.isStudentCatalog
                          ? l10n.studentBooksTitle
                          : l10n.chooseYourBook,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      l10n.booksAvailable(bookCount),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const _HomeHeaderAppIcon(),
            ],
          ),
          const SizedBox(height: 16),
          const _SearchField(),
        ],
      ),
    );
  }
}

class _HomeHeaderAppIcon extends ConsumerWidget {
  const _HomeHeaderAppIcon();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(visibleStoriesProvider);
    final stories =
        storiesAsync.valueOrNull
            ?.where((story) => !story.hasGrammarGame)
            .toList() ??
        const [];
    if (stories.isNotEmpty) {
      return StoryRing(stories: stories);
    }
    return AppBrandLogo(
      size: 56,
      borderRadius: 18,
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.10),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

// ───────────────────── IELTS / General track ─────────────────────

class _HomeTrackSegment extends ConsumerStatefulWidget {
  const _HomeTrackSegment({required this.pageController});

  final PageController pageController;

  @override
  ConsumerState<_HomeTrackSegment> createState() => _HomeTrackSegmentState();
}

class _HomeTrackSegmentState extends ConsumerState<_HomeTrackSegment> {
  var _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrefs());
  }

  Future<void> _loadPrefs() async {
    if (_prefsLoaded || !mounted) return;
    _prefsLoaded = true;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(kHomeBookTrackPrefsKey);
    if (!mounted) return;
    final session = ref.read(authProvider).valueOrNull;
    final canStudentTab = homeShowStudentTab(session?.user);
    if (raw == HomeBookTrack.general.name) {
      ref.read(homeBookTrackProvider.notifier).state = HomeBookTrack.general;
    } else if (raw == HomeBookTrack.student.name && canStudentTab) {
      ref.read(homeBookTrackProvider.notifier).state = HomeBookTrack.student;
    }
    if (!mounted) return;
    final t = ref.read(homeBookTrackProvider);
    final show = homeShowStudentTab(ref.read(authProvider).valueOrNull?.user);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      widget.pageController.jumpToPage(homePageIndexForTrack(t, show));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final track = ref.watch(homeBookTrackProvider);
    final showStudentSegment = homeShowStudentTab(
      ref.watch(authProvider).valueOrNull?.user,
    );

    ref.listen(authProvider, (prev, next) {
      if (homeShowStudentTab(next.valueOrNull?.user)) return;
      if (ref.read(homeBookTrackProvider) == HomeBookTrack.student) {
        ref.read(homeBookTrackProvider.notifier).state = HomeBookTrack.ielts;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          widget.pageController.jumpToPage(0);
        });
      }
    });

    if (!showStudentSegment && track == HomeBookTrack.student) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(homeBookTrackProvider.notifier).state = HomeBookTrack.ielts;
        widget.pageController.jumpToPage(0);
      });
    }

    final segmentTextStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 16,
    );

    final segments = <ButtonSegment<HomeBookTrack>>[
      ButtonSegment<HomeBookTrack>(
        value: HomeBookTrack.ielts,
        label: Text(l10n.homeTrackIelts, style: segmentTextStyle),
        icon: const Icon(Icons.school_outlined, size: 24),
      ),
      ButtonSegment<HomeBookTrack>(
        value: HomeBookTrack.general,
        label: Text(l10n.homeTrackGeneral, style: segmentTextStyle),
        icon: const Icon(Icons.menu_book_outlined, size: 24),
      ),
      if (showStudentSegment)
        ButtonSegment<HomeBookTrack>(
          value: HomeBookTrack.student,
          label: Text(l10n.tabStudents, style: segmentTextStyle),
          icon: const Icon(Icons.groups_2_outlined, size: 24),
        ),
    ];

    var selected = track;
    if (!showStudentSegment && track == HomeBookTrack.student) {
      selected = HomeBookTrack.ielts;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: SegmentedButton<HomeBookTrack>(
        segments: segments,
        selected: {selected},
        onSelectionChanged: (next) async {
          final v = next.first;
          ref.read(homeBookTrackProvider.notifier).state = v;
          final p = await SharedPreferences.getInstance();
          await p.setString(kHomeBookTrackPrefsKey, v.name);
          final show = homeShowStudentTab(
            ref.read(authProvider).valueOrNull?.user,
          );
          final idx = homePageIndexForTrack(v, show);
          if (widget.pageController.hasClients) {
            await widget.pageController.animateToPage(
              idx,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            );
          }
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.standard,
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 52)),
          textStyle: WidgetStateProperty.all(segmentTextStyle),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onSecondaryContainer;
            }
            return scheme.onSurfaceVariant;
          }),
        ),
      ),
    );
  }
}

/// Stable, locale-independent key so Cambridge volumes group even if API omits `series_title`.
String _seriesGroupKey(Book b) {
  final st = (b.seriesTitle ?? '').trim();
  if (st.isNotEmpty) {
    if (st == 'Cambridge IELTS') return 'cambridge_ielts';
    return 'named:$st';
  }
  final low = b.title.toLowerCase();
  if (low.startsWith('cambridge ielts')) return 'cambridge_ielts';
  if (low.startsWith('oxford word skills')) {
    return 'named:Oxford Word Skills';
  }
  if (low.startsWith('official ielts practice')) {
    return 'named:Official IELTS Practice';
  }
  if (low.startsWith('ielts vocabulary in use')) {
    return 'named:IELTS Vocabulary in Use';
  }
  return 'other';
}

List<({String groupKey, List<Book> books})> _groupBooksBySeries(
  List<Book> books,
) {
  if (books.isEmpty) return [];
  final sorted = List<Book>.of(books)
    ..sort((a, b) {
      var c = a.seriesSortOrder.compareTo(b.seriesSortOrder);
      if (c != 0) return c;
      c = a.volumeOrder.compareTo(b.volumeOrder);
      if (c != 0) return c;
      c = a.sortOrder.compareTo(b.sortOrder);
      if (c != 0) return c;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

  String keyOf(Book b) => _seriesGroupKey(b);

  final out = <({String groupKey, List<Book> books})>[];
  var curKey = keyOf(sorted.first);
  var curList = <Book>[sorted.first];
  for (var i = 1; i < sorted.length; i++) {
    final b = sorted[i];
    final k = keyOf(b);
    if (k == curKey) {
      curList.add(b);
    } else {
      out.add((groupKey: curKey, books: curList));
      curKey = k;
      curList = [b];
    }
  }
  out.add((groupKey: curKey, books: curList));
  return out;
}

class _IeltsHomeEntry {
  _IeltsHomeEntry._({this.groupKey, this.books, this.book})
    : assert((groupKey != null && books != null) || book != null);

  factory _IeltsHomeEntry.series(String groupKey, List<Book> books) {
    return _IeltsHomeEntry._(groupKey: groupKey, books: books);
  }

  factory _IeltsHomeEntry.book(Book book) {
    return _IeltsHomeEntry._(book: book);
  }

  final String? groupKey;
  final List<Book>? books;
  final Book? book;

  bool get isSeries => groupKey != null;
}

List<_IeltsHomeEntry> _ieltsHomeEntries(
  List<({String groupKey, List<Book> books})> groups,
) {
  final out = <_IeltsHomeEntry>[];
  for (final g in groups) {
    if (g.groupKey == 'other') {
      for (final b in g.books) {
        out.add(_IeltsHomeEntry.book(b));
      }
    } else {
      out.add(_IeltsHomeEntry.series(g.groupKey, g.books));
    }
  }
  return out;
}

int _minBookSortOrder(Iterable<Book> books) =>
    books.map((b) => b.sortOrder).reduce((a, b) => a < b ? a : b);

/// API / model use 999999 when there is no [book_series] row (see `books.php`).
const int _kNoSeriesSortOrderSentinel = 999999;

/// Home list rank for a **series** row: `book_series.sort_order` when present;
/// otherwise (legacy title-only grouping) fall back to min `books.order`.
int _homeListRankForSeries(List<Book> books) {
  final s = books.first.seriesSortOrder;
  if (s >= _kNoSeriesSortOrderSentinel) {
    return _minBookSortOrder(books);
  }
  return s;
}

/// IELTS & General tabs: `series_id` → one row per series; standalone books; unified sort.
List<_IeltsHomeEntry> _trackHomeEntriesForTrack(List<Book> books) {
  final bySeriesId = <int, List<Book>>{};
  final withoutSeriesId = <Book>[];

  for (final b in books) {
    if (b.seriesId != null) {
      bySeriesId.putIfAbsent(b.seriesId!, () => []).add(b);
    } else {
      withoutSeriesId.add(b);
    }
  }

  for (final list in bySeriesId.values) {
    sortBooksInSeriesDisplayOrder(list);
  }

  final ranked = <({int rank, _IeltsHomeEntry entry})>[];

  for (final e in bySeriesId.entries) {
    final list = e.value;
    ranked.add((
      rank: _homeListRankForSeries(list),
      entry: _IeltsHomeEntry.series('sid:${e.key}', list),
    ));
  }

  final legacy = _ieltsHomeEntries(_groupBooksBySeries(withoutSeriesId));
  for (final entry in legacy) {
    final rank = entry.isSeries
        ? _homeListRankForSeries(entry.books!)
        : entry.book!.sortOrder;
    ranked.add((rank: rank, entry: entry));
  }

  ranked.sort((a, b) {
    var c = a.rank.compareTo(b.rank);
    if (c != 0) return c;
    if (a.entry.isSeries != b.entry.isSeries) {
      return a.entry.isSeries ? -1 : 1;
    }
    if (a.entry.isSeries && b.entry.isSeries) {
      c = a.entry.books!.first.seriesSortOrder.compareTo(
        b.entry.books!.first.seriesSortOrder,
      );
      if (c != 0) return c;
      final ida = a.entry.books!.first.seriesId;
      final idb = b.entry.books!.first.seriesId;
      if (ida != null && idb != null) return ida.compareTo(idb);
      return (a.entry.groupKey ?? '').compareTo(b.entry.groupKey ?? '');
    }
    c = a.entry.book!.sortOrder.compareTo(b.entry.book!.sortOrder);
    if (c != 0) return c;
    return a.entry.book!.id.compareTo(b.entry.book!.id);
  });

  return ranked.map((r) => r.entry).toList();
}

class _IeltsSeriesCard extends StatelessWidget {
  const _IeltsSeriesCard({
    required this.title,
    required this.bookCount,
    required this.index,
    required this.onTap,
  });

  final String title;
  final int bookCount;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final accents = homeBookCardAccents(index);
    final locale = Localizations.localeOf(context);
    final rtlSubtitle =
        locale.languageCode == 'fa' || locale.languageCode == 'ckb';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accents.first.withValues(alpha: 0.18),
                accents.last.withValues(alpha: 0.08),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accents.first.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.collections_bookmark_rounded,
                      color: accents.first,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: double.infinity,
                child: Directionality(
                  textDirection: rtlSubtitle
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: Text(
                    l10n.homeSeriesVolumesCount(bookCount),
                    textAlign: rtlSubtitle ? TextAlign.right : TextAlign.left,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────── Search Field (ایزوله) ─────────────────────

class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.watch(searchControllerProvider);

    return TextField(
      controller: controller,
      autofocus: false,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: l10n.searchBooksHint,
        filled: true,
        fillColor: scheme.surface.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ───────────────────── Grammar practice banner ─────────────────────
// (unused while sliver is commented out — restore sliver above to re-enable)

// ignore: unused_element
class _GrammarPracticeBanner extends StatelessWidget {
  const _GrammarPracticeBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/grammar'),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.85),
                  scheme.secondary.withValues(alpha: 0.75),
                ],
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.rule_rounded, color: scheme.onPrimary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.grammarPracticeTitle,
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        l10n.grammarPracticeSubtitle,
                        style: TextStyle(
                          color: scheme.onPrimary.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: scheme.onPrimary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────── Home floating actions ─────────────────────
class _HomeFloatingActions extends StatelessWidget {
  const _HomeFloatingActions({required this.showMessageFab});

  final bool showMessageFab;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _HomeLeagueFab(),
        if (showMessageFab) ...[
          const SizedBox(height: 12),
          const _HomeTeacherOrStudentFab(),
        ],
      ],
    );
  }
}

class _HomeLeagueFab extends StatelessWidget {
  const _HomeLeagueFab();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE1306C).withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/league'),
            child: Ink(
              height: 52,
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 18, 0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF58529),
                    Color(0xFFE1306C),
                    Color(0xFF8134AF),
                  ],
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'League',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTeacherOrStudentFab extends ConsumerWidget {
  const _HomeTeacherOrStudentFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).valueOrNull;
    if (session == null) return const SizedBox.shrink();
    final u = session.user;
    final fabUnread = ref.watch(teacherMessagesUnreadFabProvider);
    final fabCount = fabUnread.when(
      data: (v) => v,
      loading: () => 0,
      error: (_, __) => 0,
    );
    if (u.isTeacher || u.isAdmin) {
      return _HomeTeacherStudentsFab(
        count: fabCount,
        onPressed: () => context.push('/teacher'),
      );
    }
    return _HomeStudentPanelFab(
      count: fabCount,
      onPressed: () => context.push('/student-panel'),
    );
  }
}

class _HomeTeacherStudentsFab extends StatelessWidget {
  const _HomeTeacherStudentsFab({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Badge(
      isLabelVisible: count > 0,
      backgroundColor: const Color(0xFFFFD60A),
      textColor: const Color(0xFF2B2100),
      label: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
      child: FloatingActionButton.extended(
        heroTag: 'home_teacher_students_fab',
        onPressed: onPressed,
        backgroundColor: _kHomeFabHappyBlue,
        foregroundColor: Colors.white,
        tooltip: l10n.tabStudents,
        icon: const Icon(Icons.groups_rounded),
        label: Text(
          l10n.tabStudents,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _HomeStudentPanelFab extends StatelessWidget {
  const _HomeStudentPanelFab({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Badge(
      isLabelVisible: count > 0,
      backgroundColor: scheme.error,
      textColor: scheme.onError,
      label: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
      child: FloatingActionButton.extended(
        heroTag: 'home_student_panel_fab',
        onPressed: onPressed,
        backgroundColor: _kHomeFabHappyBlue,
        foregroundColor: Colors.white,
        tooltip: l10n.studentPanelFabTooltip,
        icon: const Icon(Icons.space_dashboard_rounded),
        label: Text(
          l10n.myPanelFab,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
