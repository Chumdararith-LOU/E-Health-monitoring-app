DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int n) =>
    DateTime(d.year, d.month, d.day + n, d.hour, d.minute, d.second, d.millisecond);

/// Local calendar key YYYY-MM-DD.
String dayKey(DateTime d) =>
    '${d.year}-${'${d.month}'.padLeft(2, '0')}-${'${d.day}'.padLeft(2, '0')}';

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// "Morning" for the FR-05 duplicate check: before 12:00 local time.
bool isMorning(DateTime d) => d.hour < 12;
