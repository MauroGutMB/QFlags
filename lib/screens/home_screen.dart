import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'how_to_screen.dart';
import 'mode_select_screen.dart';
import 'ranking_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _heroFlags = [
    (code: 'br', angle: -0.14),
    (code: 'jp', angle: 0.10),
    (code: 'ca', angle: 0.09),
    (code: 'fr', angle: -0.10),
  ];

  void _go(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return QScreen(
      child: Column(
        children: [
          const SettingsControls(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 190,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final f in _heroFlags)
                        Transform.rotate(
                          angle: f.angle,
                          child: Image.asset(
                            'assets/flags/${f.code}.png',
                            width: 90,
                            height: 90,
                            excludeFromSemantics: true,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    text: 'Q',
                    style: display(56, color: c.text),
                    children: [TextSpan(text: 'Flags', style: TextStyle(color: c.primary))],
                  ),
                  semanticsLabel: context.tr('app_title'),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('tagline'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: c.muted),
                ),
              ],
            ),
          ),
          BigButton(
            label: context.tr('play'),
            style: BigButtonStyle.primary,
            height: 60,
            onPressed: () => _go(context, const ModeSelectScreen()),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: context.tr('how_to_play'),
            onPressed: () => _go(context, const HowToScreen()),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: context.tr('ranking'),
            onPressed: () => _go(context, const RankingScreen()),
          ),
        ],
      ),
    );
  }
}
