import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../models/match_performance.dart';
import '../../services/match_history_service.dart';

/// ============================================================
/// PROTOTYPE — THROWAWAY. Not production. Delete after a variant wins.
///
/// Three radically-different *Authored-style* layouts for Match History,
/// switchable from a floating bottom bar (arrows or ← / → keys).
///
///   A — Ledger     chronological, month-grouped, scoreline-anchored rows.
///   B — Rivalries  reorganised by opponent: H2H record + scoreline chips.
///   C — Timeline   vertical court-surface spine, big scorelines per node.
///
/// Shared Authored DNA: mono scorelines with lost sets dimmed, court-surface
/// colour accents, demoted chrome, net-tick baselines, zero gradients.
///
/// Question being answered: "Which Authored structure fits Match History?"
/// Reachable from Settings (debug builds only).
/// ============================================================
class MatchHistoryPrototype extends StatefulWidget {
  const MatchHistoryPrototype({super.key});

  @override
  State<MatchHistoryPrototype> createState() => _MatchHistoryPrototypeState();
}

class _MatchHistoryPrototypeState extends State<MatchHistoryPrototype> {
  final MatchHistoryService _service = MatchHistoryService();
  final FocusNode _focus = FocusNode();

  List<MatchPerformance> _matches = [];
  bool _loading = true;
  int _variant = 0; // 0=A, 1=B, 2=C

  static const _names = ['Ledger', 'Rivalries', 'Timeline'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final matches = await _service.getAllMatches();
    if (!mounted) return;
    setState(() {
      _matches = matches;
      _loading = false;
    });
  }

  void _cycle(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _variant = (_variant + delta) % 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _cycle(1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _cycle(2);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _matches.isEmpty
                      ? _empty()
                      : _buildVariant(),
            ),
            _switcher(),
          ],
        ),
      ),
    );
  }

  Widget _buildVariant() {
    switch (_variant) {
      case 1:
        return _VariantRivalries(matches: _matches, onTap: _showDetail);
      case 2:
        return _VariantTimeline(matches: _matches, onTap: _showDetail);
      case 0:
      default:
        return _VariantLedger(matches: _matches, onTap: _showDetail);
    }
  }

  Widget _empty() => Center(
        child: Text('No matches to prototype with',
            style: AppTheme.bodyMediumThemed(context)),
      );

  // ---- Floating switcher (debug-only by construction) ----
  Widget _switcher() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 28,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.isDark(context)
                ? Colors.white.withValues(alpha: 0.95)
                : Colors.black.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _arrow(Icons.chevron_left_rounded, () => _cycle(2)),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PROTOTYPE · throwaway',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: (AppTheme.isDark(context)
                              ? Colors.black
                              : Colors.white)
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${String.fromCharCode(65 + _variant)} — ${_names[_variant]}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.isDark(context)
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              _arrow(Icons.chevron_right_rounded, () => _cycle(1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    final fg = AppTheme.isDark(context) ? Colors.black : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: fg, size: 24),
      ),
    );
  }

  void _showDetail(MatchPerformance m) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (ctx) {
        final isWin = m.result.toLowerCase() == 'win';
        final accent = AppTheme.surfaceAccent(m.surface);
        return Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(isWin ? 'Beat' : 'Lost to',
                      style: AppTheme.bodyMediumThemed(ctx)
                          .copyWith(color: AppTheme.textMutedColor(ctx))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(m.opponent,
                        style: AppTheme.headingMediumThemed(ctx)),
                  ),
                  _SurfaceTag(surface: m.surface, accent: accent),
                ],
              ),
              const SizedBox(height: 16),
              _Scoreline(
                  raw: m.scoreLine.isNotEmpty
                      ? m.scoreLine
                      : '${m.setsWon}-${m.setsLost}',
                  size: 40),
              if (m.matchSummary.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(m.matchSummary, style: AppTheme.bodyMediumThemed(ctx)),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
//  VARIANT A — LEDGER (chronological, month-grouped)
// ============================================================
class _VariantLedger extends StatelessWidget {
  const _VariantLedger({required this.matches, required this.onTap});

  final List<MatchPerformance> matches;
  final void Function(MatchPerformance) onTap;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByMonth(matches);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLG, AppTheme.spaceLG, AppTheme.spaceLG, 120),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('RESULTS',
                style:
                    AppTheme.labelThemed(context).copyWith(letterSpacing: 2)),
            const Spacer(),
            Text('${matches.length}',
                style: AppTheme.scorelineThemed(context, size: 18)),
          ],
        ),
        const SizedBox(height: 10),
        const _CourtBaseline(),
        const SizedBox(height: 18),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(entry.key.toUpperCase(),
                style: AppTheme.scorelineThemed(
                  context,
                  size: 12,
                  color: AppTheme.textMutedColor(context),
                )),
          ),
          for (final m in entry.value) _row(context, m),
          const SizedBox(height: 22),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, MatchPerformance m) {
    final isWin = m.result.toLowerCase() == 'win';
    final accent = AppTheme.surfaceAccent(m.surface);
    final primary = AppTheme.textPrimaryColor(context);
    final muted = AppTheme.textMutedColor(context);

    return InkWell(
      onTap: () => onTap(m),
      child: Container(
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: AppTheme.borderColor(context))),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: Text(
                isWin ? 'W' : 'L',
                style: AppTheme.scorelineThemed(
                  context,
                  size: 15,
                  color: isWin ? primary : muted.withValues(alpha: 0.55),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.opponent,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headingSmallThemed(context)
                          .copyWith(fontSize: 17, letterSpacing: -0.2)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration:
                            BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('${_dayMonth(m.date)} · ${m.surface}',
                          style: AppTheme.bodySmallThemed(context)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _Scoreline(
                raw: m.scoreLine.isNotEmpty
                    ? m.scoreLine
                    : '${m.setsWon}-${m.setsLost}',
                size: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  VARIANT B — RIVALRIES (grouped by opponent)
// ============================================================
class _VariantRivalries extends StatelessWidget {
  const _VariantRivalries({required this.matches, required this.onTap});

  final List<MatchPerformance> matches;
  final void Function(MatchPerformance) onTap;

  @override
  Widget build(BuildContext context) {
    final rivalries = _buildRivalries(matches);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLG, AppTheme.spaceLG, AppTheme.spaceLG, 120),
      children: [
        Text('RIVALRIES',
            style: AppTheme.labelThemed(context).copyWith(letterSpacing: 2)),
        const SizedBox(height: 6),
        Text('${rivalries.length} opponents · ${matches.length} matches',
            style: AppTheme.bodySmallThemed(context)),
        const SizedBox(height: 20),
        for (final r in rivalries) ...[
          _rivalryBlock(context, r),
          const SizedBox(height: 26),
        ],
      ],
    );
  }

  Widget _rivalryBlock(BuildContext context, _Rivalry r) {
    final leading = r.wins >= r.losses;
    final primary = AppTheme.textPrimaryColor(context);
    final muted = AppTheme.textMutedColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(r.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingMediumThemed(context)
                      .copyWith(letterSpacing: -0.5)),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                Text('${r.wins}',
                    style: AppTheme.scorelineThemed(context,
                        size: 22, color: leading ? primary : muted)),
                Text('–',
                    style:
                        AppTheme.scorelineThemed(context, size: 22, color: muted)),
                Text('${r.losses}',
                    style: AppTheme.scorelineThemed(context,
                        size: 22, color: leading ? muted : primary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(leading ? 'You lead' : (r.wins == r.losses ? 'Even' : 'You trail'),
            style: AppTheme.bodySmallThemed(context)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final m in r.matches) _chip(context, m)],
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, MatchPerformance m) {
    final isWin = m.result.toLowerCase() == 'win';
    final accent = AppTheme.surfaceAccent(m.surface);
    final score = m.scoreLine.isNotEmpty
        ? m.scoreLine
        : '${m.setsWon}-${m.setsLost}';

    return InkWell(
      onTap: () => onTap(m),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isWin
                ? AppTheme.textPrimaryColor(context).withValues(alpha: 0.35)
                : AppTheme.borderColor(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            _Scoreline(raw: score, size: 15),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  VARIANT C — TIMELINE (court-surface spine)
// ============================================================
class _VariantTimeline extends StatelessWidget {
  const _VariantTimeline({required this.matches, required this.onTap});

  final List<MatchPerformance> matches;
  final void Function(MatchPerformance) onTap;

  @override
  Widget build(BuildContext context) {
    final form = matches.take(8).toList().reversed.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLG, AppTheme.spaceLG, AppTheme.spaceLG, 120),
      children: [
        Text('RECENT FORM',
            style: AppTheme.labelThemed(context).copyWith(letterSpacing: 2)),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final m in form)
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: Text(
                  m.result.toLowerCase() == 'win' ? 'W' : 'L',
                  style: AppTheme.scorelineThemed(
                    context,
                    size: 14,
                    color: m.result.toLowerCase() == 'win'
                        ? AppTheme.textPrimaryColor(context)
                        : AppTheme.textMutedColor(context)
                            .withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        for (int i = 0; i < matches.length; i++)
          _node(context, matches[i], isLast: i == matches.length - 1),
      ],
    );
  }

  Widget _node(BuildContext context, MatchPerformance m,
      {required bool isLast}) {
    final isWin = m.result.toLowerCase() == 'win';
    final accent = AppTheme.surfaceAccent(m.surface);
    final score = m.scoreLine.isNotEmpty
        ? m.scoreLine
        : '${m.setsWon}-${m.setsLost}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spine
          Column(
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: isWin ? accent : AppTheme.scaffoldBackground(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2),
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast
                      ? Colors.transparent
                      : accent.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 26),
              child: InkWell(
                onTap: () => onTap(m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${isWin ? 'Beat' : 'Lost to'} ${m.opponent}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.headingSmallThemed(context)
                                .copyWith(fontSize: 17),
                          ),
                        ),
                        _SurfaceTag(surface: m.surface, accent: accent),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(_dayMonth(m.date),
                        style: AppTheme.bodySmallThemed(context)),
                    const SizedBox(height: 8),
                    _Scoreline(raw: score, size: 30),
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

// ============================================================
//  SHARED AUTHORED PRIMITIVES
// ============================================================

/// Mono scoreline, lost sets dimmed. Handles tiebreaks like 7-6(5).
class _Scoreline extends StatelessWidget {
  const _Scoreline({required this.raw, this.size = 24});

  final String raw;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sets =
        raw.trim().isEmpty ? const <String>[] : raw.trim().split(RegExp(r'\s+'));
    if (sets.isEmpty) {
      return Text('—', style: AppTheme.scorelineThemed(context, size: size));
    }
    final won = AppTheme.textPrimaryColor(context);
    final lost = AppTheme.textMutedColor(context).withValues(alpha: 0.5);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final s in sets)
          Padding(
            padding: EdgeInsets.only(right: size * 0.32),
            child: Text(
              s,
              style: AppTheme.scorelineThemed(
                context,
                size: size,
                color: _wonSet(s) ? won : lost,
              ),
            ),
          ),
      ],
    );
  }

  bool _wonSet(String token) {
    final clean = token.replaceAll(RegExp(r'\(.*?\)'), '');
    final parts = clean.split('-');
    if (parts.length < 2) return true;
    final me = int.tryParse(parts[0].trim()) ?? 0;
    final opp = int.tryParse(parts[1].trim()) ?? 0;
    return me >= opp;
  }
}

class _SurfaceTag extends StatelessWidget {
  const _SurfaceTag({required this.surface, required this.accent});

  final String surface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(surface.toUpperCase(),
            style: AppTheme.labelThemed(context)
                .copyWith(color: accent, letterSpacing: 1.2)),
      ],
    );
  }
}

class _CourtBaseline extends StatelessWidget {
  const _CourtBaseline();

  @override
  Widget build(BuildContext context) {
    final line = AppTheme.borderColor(context);
    return SizedBox(
      height: 8,
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: line)),
          Container(width: 1, height: 8, color: line),
          Expanded(child: Container(height: 1, color: line)),
        ],
      ),
    );
  }
}

class _Rivalry {
  _Rivalry(this.name);
  final String name;
  int wins = 0;
  int losses = 0;
  final List<MatchPerformance> matches = [];
  int get total => wins + losses;
}

List<_Rivalry> _buildRivalries(List<MatchPerformance> matches) {
  final Map<String, _Rivalry> map = {};
  for (final m in matches) {
    final name = m.opponent.trim();
    if (name.isEmpty || name.toLowerCase() == 'unknown') continue;
    final r = map.putIfAbsent(name.toLowerCase(), () => _Rivalry(name));
    if (m.result.toLowerCase() == 'win') {
      r.wins++;
    } else {
      r.losses++;
    }
    r.matches.add(m);
  }
  final list = map.values.toList()
    ..sort((a, b) => b.total.compareTo(a.total));
  return list;
}

Map<String, List<MatchPerformance>> _groupByMonth(
    List<MatchPerformance> matches) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June', //
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final Map<String, List<MatchPerformance>> out = {};
  for (final m in matches) {
    final key = "${months[m.date.month - 1]} ${m.date.year}";
    out.putIfAbsent(key, () => []).add(m);
  }
  return out;
}

String _dayMonth(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays == 0) return 'Today';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[date.month - 1]} ${date.day}';
}

/// Debug-only guard so a stray merge can't ship the prototype entry point.
bool get prototypesEnabled => kDebugMode;
