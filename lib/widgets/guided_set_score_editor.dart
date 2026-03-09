import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/match_format_utils.dart';

class GuidedSetScoreEditor extends StatefulWidget {
  final String matchFormat;
  final String? initialScoreLine;
  final void Function(String scoreLine, MatchScoreParseResult? parsed, String? error) onChanged;

  const GuidedSetScoreEditor({
    super.key,
    required this.matchFormat,
    required this.onChanged,
    this.initialScoreLine,
  });

  @override
  State<GuidedSetScoreEditor> createState() => _GuidedSetScoreEditorState();
}

class _GuidedSetScoreValue {
  int? you;
  int? opp;
  int? tiebreak;
}

class _GuidedSetScoreEditorState extends State<GuidedSetScoreEditor> {
  final TextEditingController _scoreController = TextEditingController();
  final List<_GuidedSetScoreValue> _sets =
      List.generate(3, (_) => _GuidedSetScoreValue());

  @override
  void initState() {
    super.initState();
    if (widget.initialScoreLine != null && widget.initialScoreLine!.trim().isNotEmpty) {
      _scoreController.text = widget.initialScoreLine!.trim();
    }
    _emitState();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  bool _showTiebreak(int? you, int? opp) {
    if (you == null || opp == null) return false;
    if (widget.matchFormat == MatchFormat.fast4) {
      return (you == 4 && opp == 3) || (you == 3 && opp == 4);
    }
    return (you == 7 && opp == 6) || (you == 6 && opp == 7);
  }

  void _syncScoreLineFromGuided() {
    final parts = <String>[];
    for (final set in _sets) {
      if (set.you == null || set.opp == null) continue;
      final withTb = _showTiebreak(set.you, set.opp) && set.tiebreak != null;
      parts.add(withTb ? '${set.you}-${set.opp}(${set.tiebreak})' : '${set.you}-${set.opp}');
    }
    if (parts.isNotEmpty) {
      _scoreController.text = parts.join(' ');
    }
    _emitState();
  }

  void _emitState() {
    final scoreLine = _scoreController.text.trim();
    if (scoreLine.isEmpty) {
      widget.onChanged('', null, 'Enter the score');
      return;
    }

    final error = MatchScoreValidator.validate(widget.matchFormat, scoreLine);
    if (error != null) {
      widget.onChanged(scoreLine, null, error);
      return;
    }

    widget.onChanged(scoreLine, MatchScoreValidator.parse(widget.matchFormat, scoreLine), null);
  }

  Widget _gamesDropdown({
    required int? value,
    required String label,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      isDense: true,
      decoration: AppTheme.inputDecorationThemed(context, label: label),
      items: List.generate(8, (i) => i)
          .map((games) => DropdownMenuItem<int>(value: games, child: Text(games.toString())))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _setRow(int index) {
    final set = _sets[index];
    final showTb = _showTiebreak(set.you, set.opp);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      padding: const EdgeInsets.all(AppTheme.spaceSM),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text('Set ${index + 1}', style: AppTheme.bodySmallThemed(context))),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: _gamesDropdown(
              value: set.you,
              label: 'You',
              onChanged: (value) {
                setState(() {
                  set.you = value;
                  if (!_showTiebreak(set.you, set.opp)) set.tiebreak = null;
                  _syncScoreLineFromGuided();
                });
              },
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: _gamesDropdown(
              value: set.opp,
              label: 'Opp',
              onChanged: (value) {
                setState(() {
                  set.opp = value;
                  if (!_showTiebreak(set.you, set.opp)) set.tiebreak = null;
                  _syncScoreLineFromGuided();
                });
              },
            ),
          ),
          if (showTb) ...[
            const SizedBox(width: AppTheme.spaceSM),
            SizedBox(
              width: 86,
              child: DropdownButtonFormField<int>(
                value: set.tiebreak,
                isDense: true,
                decoration: AppTheme.inputDecorationThemed(context, label: 'TB'),
                items: List.generate(13, (i) => i)
                    .map((tb) => DropdownMenuItem<int>(value: tb, child: Text(tb.toString())))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    set.tiebreak = value;
                    _syncScoreLineFromGuided();
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(3, _setRow),
        const SizedBox(height: AppTheme.spaceSM),
        TextFormField(
          controller: _scoreController,
          onChanged: (_) => _emitState(),
          style: AppTheme.bodyMediumThemed(context).copyWith(color: AppTheme.textPrimaryColor(context)),
          decoration: AppTheme.inputDecorationThemed(
            context,
            label: 'Score line',
            hint: widget.matchFormat == MatchFormat.fast4 ? 'e.g. 4-1 4-3(5)' : 'e.g. 6-4 7-6(5)',
          ),
        ),
      ],
    );
  }
}

