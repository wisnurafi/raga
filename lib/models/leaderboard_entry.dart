// One row of the community leaderboard, as returned by the
// get_leaderboard RPC. Only display name, avatar and the computed
// metric — never raw health data.

class LeaderboardEntry {
  final String displayName;
  final String? avatarUrl;

  /// % weight lost this week (metric 'pct_loss') or streak weeks
  /// (metric 'streak').
  final double value;

  const LeaderboardEntry({
    required this.displayName,
    this.avatarUrl,
    required this.value,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) {
    return LeaderboardEntry(
      displayName: (j['display_name'] as String? ?? '').trim(),
      avatarUrl: j['avatar_url'] as String?,
      value: (j['value'] as num? ?? 0).toDouble(),
    );
  }
}
