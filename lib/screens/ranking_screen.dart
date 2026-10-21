import 'package:flutter/material.dart';

import '../data/ranking_db.dart';
import '../l10n/strings.dart';
import '../models/game_mode.dart';
import '../models/score.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key, this.initialMode = GameMode.memory});

  final GameMode initialMode;

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late GameMode _mode = widget.initialMode;
  late Future<List<Score>> _scores = RankingDb.instance.top(_mode);

  void _select(GameMode mode) => setState(() {
        _mode = mode;
        _scores = RankingDb.instance.top(mode);
      });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return QScreen(
      child: Column(
        children: [
          ScreenHeader(title: context.tr('ranking')),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: c.track, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                for (final mode in GameMode.values)
                  Expanded(child: _tab(c, mode)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<Score>>(
              future: _scores,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final scores = snap.data ?? const [];
                if (scores.isEmpty) {
                  return Center(
                    child: Text(
                      context.tr('ranking_empty'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: c.muted, height: 1.5),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: scores.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _row(c, i + 1, scores[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(QColors c, GameMode mode) {
    final selected = mode == _mode;
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? c.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _select(mode),
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                context.tr(mode.titleKey),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? c.text : c.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(QColors c, int position, Score score) {
    // Ouro, prata e bronze para o pódio.
    const medals = [Color(0xFFFFC14D), Color(0xFFCBD5E1), Color(0xFFF0B58A)];
    final medal = position <= 3 ? medals[position - 1] : null;
    final d = score.createdAt;
    String two(int n) => n.toString().padLeft(2, '0');
    final date = context.lang == AppLang.pt
        ? '${two(d.day)}/${two(d.month)}/${d.year}'
        : '${two(d.month)}/${two(d.day)}/${d.year}';
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.track),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: medal ?? c.track, shape: BoxShape.circle),
            child: Text(
              '$position',
              style: display(15, color: medal != null ? const Color(0xFF0F172A) : c.text),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text),
                ),
                Text(date, style: TextStyle(fontSize: 12, color: c.muted)),
              ],
            ),
          ),
          Text('${score.points}', style: display(20, color: _mode.accent(c))),
        ],
      ),
    );
  }
}
