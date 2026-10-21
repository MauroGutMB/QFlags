import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../data/ranking_db.dart';
import '../l10n/strings.dart';
import '../models/game_mode.dart';
import '../models/score.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'game_screen.dart';
import 'ranking_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.mode, required this.correct, required this.wrong});

  final GameMode mode;
  final int correct;
  final int wrong;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // Preenchido com o último nome usado, para não precisar digitar de novo.
  late final _name = TextEditingController(text: SettingsScope.of(context).lastName);
  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('name_required'))));
      return;
    }
    setState(() => _saving = true);
    await RankingDb.instance.insert(Score(
      name: name,
      mode: widget.mode,
      points: widget.correct,
      createdAt: DateTime.now(),
    ));
    if (!mounted) return;
    SettingsScope.of(context).setLastName(name);
    setState(() {
      _saving = false;
      _saved = true;
    });
  }

  void _replace(Widget screen) =>
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = widget.mode.accent(c);
    return QScreen(
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          '${context.tr(widget.mode.titleKey)} · ${context.tr('game_over')}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.muted),
                        ),
                        const SizedBox(height: 12),
                        Text('${widget.correct}', style: display(96, color: accent)),
                        Text(
                          context.tr('points'),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.text),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('stats', {'c': widget.correct, 'w': widget.wrong}),
                          style: TextStyle(fontSize: 14, color: c.muted),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  if (_saved) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: c.correct),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('saved'),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.correct),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.tr('your_name'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.muted),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _name,
                      maxLength: 20,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                      style: TextStyle(fontSize: 17, color: c.text),
                      decoration: InputDecoration(
                        hintText: context.tr('name_hint'),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  BigButton(
                    label: context.tr(_saved ? 'see_ranking' : 'save_score'),
                    style: BigButtonStyle.primary,
                    height: 60,
                    onPressed: _saving
                        ? null
                        : _saved
                            ? () => _replace(RankingScreen(initialMode: widget.mode))
                            : _save,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: BigButton(
                          label: context.tr('play_again'),
                          height: 52,
                          onPressed: () => _replace(GameScreen(mode: widget.mode)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BigButton(
                          label: context.tr('home'),
                          height: 52,
                          onPressed: () =>
                              Navigator.of(context).popUntil((route) => route.isFirst),
                        ),
                      ),
                    ],
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
