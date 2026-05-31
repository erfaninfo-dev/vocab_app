class TeacherStudentSummary {
  const TeacherStudentSummary({
    required this.id,
    required this.email,
    this.displayName,
    this.avatar = 'm1',
    required this.sessionCount,
    this.sessionsUpdatedAt,
    this.teacherNote,
    this.unreadFromStudent = 0,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.lastMessageFromTeacher,
    this.sessionPrice,
    this.defaultTermFee,
    this.currencyCode = 'IRR',
    this.totalReceived,
    this.totalUnpaid,
    this.hasUnpaid = false,
    this.pricingAvailable = false,
  });

  final int id;
  final String email;
  final String? displayName;
  final String avatar;
  final int sessionCount;
  final String? sessionsUpdatedAt;

  /// Private note from `teacher_student_sessions.note` (server).
  final String? teacherNote;

  /// When [inbox] list from API: unread messages **from this student** (teacher inbox).
  final int unreadFromStudent;

  /// Latest message time in thread (any direction), from `teacher_students.php?inbox=1`.
  final String? lastMessageAt;

  /// Truncated last message body for inbox row (Telegram-style preview).
  final String? lastMessagePreview;

  /// Whether the latest message in thread was sent by the teacher (`1` in JSON).
  final bool? lastMessageFromTeacher;

  final double? sessionPrice;
  final double? defaultTermFee;
  final String currencyCode;
  final double? totalReceived;
  final double? totalUnpaid;
  final bool hasUnpaid;
  final bool pricingAvailable;

  String get displayLabel {
    final d = displayName?.trim();
    if (d != null && d.isNotEmpty) {
      return d;
    }
    return email;
  }

  bool get hasSessionPriceSet => effectiveDefaultTermFee > 0;

  double get effectiveDefaultTermFee =>
      defaultTermFee ?? sessionPrice ?? 0;

  bool get hasDefaultTermFeeSet => effectiveDefaultTermFee > 0;

  factory TeacherStudentSummary.fromJson(Map<String, dynamic> json) {
    return TeacherStudentSummary(
      id: (json['id'] as num).toInt(),
      email: (json['email'] ?? '').toString(),
      displayName: json['display_name']?.toString(),
      avatar: (json['avatar']?.toString().isNotEmpty ?? false)
          ? json['avatar'].toString()
          : 'm1',
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      sessionsUpdatedAt: json['sessions_updated_at']?.toString(),
      teacherNote: () {
        final n = json['note'];
        if (n == null) return null;
        final s = n.toString().trim();
        return s.isEmpty ? null : s;
      }(),
      unreadFromStudent: (json['unread_from_student'] as num?)?.toInt() ?? 0,
      lastMessageAt: json['last_message_at']?.toString(),
      lastMessagePreview: () {
        final p = json['last_message_preview'];
        if (p == null) return null;
        final s = p.toString().trim();
        return s.isEmpty ? null : s;
      }(),
      lastMessageFromTeacher: () {
        final v = json['last_message_from_teacher'];
        if (v == null) return null;
        if (v == true || v == 1) return true;
        if (v == false || v == 0) return false;
        return null;
      }(),
      sessionPrice: (json['session_price'] as num?)?.toDouble(),
      defaultTermFee: (json['default_term_fee'] as num?)?.toDouble() ??
          (json['session_price'] as num?)?.toDouble(),
      currencyCode: (json['currency_code']?.toString().isNotEmpty ?? false)
          ? json['currency_code'].toString()
          : 'IRR',
      totalReceived: (json['total_received'] as num?)?.toDouble(),
      totalUnpaid: (json['total_unpaid'] as num?)?.toDouble(),
      hasUnpaid: json['has_unpaid'] == true || json['has_unpaid'] == 1,
      pricingAvailable:
          json.containsKey('session_price') || json['pricing_available'] == true,
    );
  }
}

/// One term (ترم) for a teacher–student pair: ordered and capped session count.
class ClassSessionTerm {
  const ClassSessionTerm({
    required this.id,
    required this.sortOrder,
    required this.sessionCap,
    required this.sessionCount,
    this.isPaid = false,
    this.termAmount,
    this.termReceived,
    this.termUnpaid,
    this.termFee,
  });

  final int id;
  final int sortOrder;
  final int sessionCap;
  final int sessionCount;

  /// Tuition / fee paid for this term (server `is_paid`).
  final bool isPaid;

  final double? termAmount;
  final double? termReceived;
  final double? termUnpaid;
  final double? termFee;

  bool get isFull => sessionCount >= sessionCap;

  double get effectiveTermFee => termFee ?? termAmount ?? 0;

  factory ClassSessionTerm.fromJson(Map<String, dynamic> json) {
    return ClassSessionTerm(
      id: (json['id'] as num).toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 1,
      sessionCap: (json['session_cap'] as num?)?.toInt() ?? 0,
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      isPaid: json['is_paid'] == true || json['is_paid'] == 1,
      termAmount: (json['term_amount'] as num?)?.toDouble(),
      termReceived: (json['term_received'] as num?)?.toDouble(),
      termUnpaid: (json['term_unpaid'] as num?)?.toDouble(),
      termFee: (json['term_fee'] as num?)?.toDouble(),
    );
  }
}

/// One recorded in-person / class session (teacher tapped +).
class ClassSessionEntry {
  const ClassSessionEntry({
    required this.id,
    required this.index,
    required this.recordedAtRaw,
    this.termId,
  });

  final int id;

  /// 1-based display index within the term when [termId] is set; otherwise global.
  final int index;

  /// Server row for `teacher_student_terms` when the API is migrated.
  final int? termId;

  /// Server datetime string for when the session was recorded.
  final String recordedAtRaw;

  factory ClassSessionEntry.fromJson(Map<String, dynamic> json) {
    return ClassSessionEntry(
      id: (json['id'] as num).toInt(),
      index: (json['index'] as num?)?.toInt() ??
          (json['session_index'] as num?)?.toInt() ??
          0,
      recordedAtRaw: (json['recorded_at'] ?? '').toString(),
      termId: (json['term_id'] as num?)?.toInt(),
    );
  }
}

class StudentFinancialSummary {
  const StudentFinancialSummary({
    required this.totalReceived,
    required this.totalUnpaid,
    required this.paidTermsCount,
    required this.unpaidTermsCount,
  });

  final double totalReceived;
  final double totalUnpaid;
  final int paidTermsCount;
  final int unpaidTermsCount;

  factory StudentFinancialSummary.fromJson(Map<String, dynamic> json) {
    return StudentFinancialSummary(
      totalReceived: (json['total_received'] as num?)?.toDouble() ?? 0,
      totalUnpaid: (json['total_unpaid'] as num?)?.toDouble() ?? 0,
      paidTermsCount: (json['paid_terms_count'] as num?)?.toInt() ?? 0,
      unpaidTermsCount: (json['unpaid_terms_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TeacherSessionInfo {
  const TeacherSessionInfo({
    required this.sessionCount,
    this.updatedAt,
    this.note,
    this.sessions = const [],
    this.terms = const [],
    this.usesTermsTable = false,
    this.sessionPrice,
    this.defaultTermFee,
    this.currencyCode = 'IRR',
    this.pricingAvailable = false,
    this.financialSummary,
    this.financialNotice,
  });

  final int sessionCount;
  final String? updatedAt;
  final String? note;
  final List<ClassSessionEntry> sessions;
  final List<ClassSessionTerm> terms;
  final bool usesTermsTable;
  final double? sessionPrice;
  final double? defaultTermFee;
  final String currencyCode;
  final bool pricingAvailable;
  final StudentFinancialSummary? financialSummary;
  final String? financialNotice;

  double get effectiveDefaultTermFee =>
      defaultTermFee ?? sessionPrice ?? 0;

  bool get hasDefaultTermFeeSet => effectiveDefaultTermFee > 0;

  bool get hasSessionPriceSet => hasDefaultTermFeeSet;
}

class StudentFinancialRow {
  const StudentFinancialRow({
    required this.studentId,
    required this.displayName,
    required this.received,
    required this.unpaid,
    required this.sessionPrice,
    this.avatar = 'm1',
    this.sessionCount = 0,
  });

  final int studentId;
  final String displayName;
  final String avatar;
  final double received;
  final double unpaid;
  final double sessionPrice;
  final int sessionCount;

  factory StudentFinancialRow.fromJson(Map<String, dynamic> json) {
    return StudentFinancialRow(
      studentId: (json['student_id'] as num).toInt(),
      displayName: (json['display_name'] ?? '').toString(),
      avatar: (json['avatar']?.toString().isNotEmpty ?? false)
          ? json['avatar'].toString()
          : 'm1',
      received: (json['received'] as num?)?.toDouble() ?? 0,
      unpaid: (json['unpaid'] as num?)?.toDouble() ?? 0,
      sessionPrice: (json['session_price'] as num?)?.toDouble() ?? 0,
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TermFinancialRow {
  const TermFinancialRow({
    required this.studentId,
    required this.displayName,
    required this.termId,
    required this.sortOrder,
    required this.sessionCount,
    required this.isPaid,
    required this.received,
    required this.unpaid,
    required this.termAmount,
  });

  final int studentId;
  final String displayName;
  final int termId;
  final int sortOrder;
  final int sessionCount;
  final bool isPaid;
  final double received;
  final double unpaid;
  final double termAmount;

  factory TermFinancialRow.fromJson(Map<String, dynamic> json) {
    return TermFinancialRow(
      studentId: (json['student_id'] as num).toInt(),
      displayName: (json['display_name'] ?? '').toString(),
      termId: (json['term_id'] as num).toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 1,
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      isPaid: json['is_paid'] == true || json['is_paid'] == 1,
      received: (json['received'] as num?)?.toDouble() ?? 0,
      unpaid: (json['unpaid'] as num?)?.toDouble() ?? 0,
      termAmount: (json['term_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TeacherFinancialTotals {
  const TeacherFinancialTotals({
    required this.received,
    required this.unpaid,
    required this.sessionCount,
    required this.paidTermCount,
    required this.unpaidTermCount,
  });

  final double received;
  final double unpaid;
  final int sessionCount;
  final int paidTermCount;
  final int unpaidTermCount;

  factory TeacherFinancialTotals.fromJson(Map<String, dynamic> json) {
    return TeacherFinancialTotals(
      received: (json['received'] as num?)?.toDouble() ?? 0,
      unpaid: (json['unpaid'] as num?)?.toDouble() ?? 0,
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      paidTermCount: (json['paid_term_count'] as num?)?.toInt() ?? 0,
      unpaidTermCount: (json['unpaid_term_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TeacherFinancialSummaryResponse {
  const TeacherFinancialSummaryResponse({
    required this.pricingAvailable,
    required this.periodLabel,
    required this.currencyCode,
    required this.totals,
    this.byStudent = const [],
    this.byTerm = const [],
  });

  final bool pricingAvailable;
  final String periodLabel;
  final String currencyCode;
  final TeacherFinancialTotals totals;
  final List<StudentFinancialRow> byStudent;
  final List<TermFinancialRow> byTerm;

  factory TeacherFinancialSummaryResponse.fromJson(Map<String, dynamic> json) {
    final rawStudents = json['by_student'] as List<dynamic>? ?? const [];
    final rawTerms = json['by_term'] as List<dynamic>? ?? const [];
    return TeacherFinancialSummaryResponse(
      pricingAvailable: json['pricing_available'] != false,
      periodLabel: (json['period_label'] ?? '').toString(),
      currencyCode: (json['currency_code']?.toString().isNotEmpty ?? false)
          ? json['currency_code'].toString()
          : 'IRR',
      totals: TeacherFinancialTotals.fromJson(
        (json['totals'] as Map<String, dynamic>?) ?? const {},
      ),
      byStudent: rawStudents
          .map((e) => StudentFinancialRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      byTerm: rawTerms
          .map((e) => TermFinancialRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

enum TeacherFinancePeriod { today, week, month, lifetime, custom }

enum TeacherFinancePaymentFilter { all, paid, unpaid }

class TeacherFinancialFilters {
  const TeacherFinancialFilters({
    this.studentId,
    this.period = TeacherFinancePeriod.lifetime,
    this.from,
    this.to,
    this.paymentStatus = TeacherFinancePaymentFilter.all,
    this.groupByStudent = true,
  });

  final int? studentId;
  final TeacherFinancePeriod period;
  final DateTime? from;
  final DateTime? to;
  final TeacherFinancePaymentFilter paymentStatus;
  final bool groupByStudent;

  @override
  bool operator ==(Object other) {
    return other is TeacherFinancialFilters &&
        other.studentId == studentId &&
        other.period == period &&
        other.from == from &&
        other.to == to &&
        other.paymentStatus == paymentStatus &&
        other.groupByStudent == groupByStudent;
  }

  @override
  int get hashCode => Object.hash(
        studentId,
        period,
        from,
        to,
        paymentStatus,
        groupByStudent,
      );
}

class TeacherStudentPricing {
  const TeacherStudentPricing({
    required this.defaultTermFee,
    required this.sessionPrice,
    required this.currencyCode,
    required this.pricingAvailable,
    this.updatedAt,
  });

  final double defaultTermFee;
  final double sessionPrice;
  final String currencyCode;
  final bool pricingAvailable;
  final String? updatedAt;

  factory TeacherStudentPricing.fromJson(Map<String, dynamic> json) {
    final fee = (json['default_term_fee'] as num?)?.toDouble() ??
        (json['session_price'] as num?)?.toDouble() ??
        0;
    return TeacherStudentPricing(
      defaultTermFee: fee,
      sessionPrice: fee,
      currencyCode: (json['currency_code']?.toString().isNotEmpty ?? false)
          ? json['currency_code'].toString()
          : 'IRR',
      pricingAvailable: json['pricing_available'] != false,
      updatedAt: json['updated_at']?.toString(),
    );
  }
}
