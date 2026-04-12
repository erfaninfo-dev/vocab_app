/// Passed as [GoRouteState.extra] when opening `/teacher/chat/:studentId` from inbox or student detail.
class TeacherChatOpenArgs {
  const TeacherChatOpenArgs({
    required this.displayTitle,
    required this.avatarId,
    required this.userId,
  });

  final String displayTitle;
  final String avatarId;
  final int userId;
}
