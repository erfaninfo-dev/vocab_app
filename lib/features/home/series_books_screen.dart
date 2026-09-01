import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_gradient_scaffold.dart';
import '../../data/models/book_model.dart' show Book, sortBooksInSeriesDisplayOrder;
import '../../l10n/app_localizations.dart';
import 'home_book_card.dart';

/// Passed via [GoRouterState.extra] for `/series-books`.
class SeriesBooksRouteArgs {
  const SeriesBooksRouteArgs({required this.title, required this.books});

  final String title;
  final List<Book> books;
}

/// Lists all books in one IELTS series (same grid pattern as [UnitsScreen]).
class SeriesBooksScreen extends StatelessWidget {
  const SeriesBooksScreen({
    super.key,
    required this.title,
    required this.books,
  });

  final String title;
  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final sortedBooks = List<Book>.of(books);
    sortBooksInSeriesDisplayOrder(sortedBooks);

    final appBar = styledAppGradientAppBar(
      context: context,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: l10n.backToBooks,
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      centerTitle: false,
    );

    return AppGradientScaffold(
      extendBodyBehindAppBar: false,
      appBar: appBar,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Text(
                l10n.seriesBooksGridHint(sortedBooks.length),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 1000
                        ? 4
                        : width >= 760
                        ? 3
                        : width >= 500
                        ? 2
                        : 1;

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: crossAxisCount == 1 ? 2.15 : 1.48,
                      ),
                      itemCount: sortedBooks.length,
                      itemBuilder: (context, index) {
                        final book = sortedBooks[index];
                        return HomeBookCard(
                          book: book,
                          index: index,
                          onTap: () => context.push('/books/${book.id}/units'),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
