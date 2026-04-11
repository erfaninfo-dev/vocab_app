import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeBookTrack { ielts, general, student }

extension HomeBookTrackApi on HomeBookTrack {
  /// Matches [Book.track] for API `ielts` / `general`. Not used for [student] row.
  String get apiValue => name;

  bool get isStudentCatalog => this == HomeBookTrack.student;
}

const kHomeBookTrackPrefsKey = 'home_book_track_v1';

final homeBookTrackProvider = StateProvider<HomeBookTrack>(
  (ref) => HomeBookTrack.ielts,
);
