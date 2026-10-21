import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/game_mode.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key});

  static const _descriptions = {
    GameMode.memory: 'how_memory',
    GameMode.timeAttack: 'how_time_attack',
    GameMode.halfFlag: 'how_half_flag',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final body = TextStyle(fontSize: 15, color: c.muted, height: 1.5);
    return QScreen(
      child: ListView(
        children: [
          ScreenHeader(title: context.tr('how_to_play')),
          const SizedBox(height: 20),
          Text(context.tr('how_intro'), style: body),
          const SizedBox(height: 16),
          for (final mode in GameMode.values) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.track),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(mode.icon, color: mode.accent(c), size: 22),
                      const SizedBox(width: 8),
                      Text(context.tr(mode.titleKey), style: display(18, color: mode.accent(c))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr(_descriptions[mode]!),
                    style: TextStyle(fontSize: 14, color: c.text, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          Text(context.tr('how_bonus'), style: body),
          const SizedBox(height: 12),
          Text(context.tr('how_outro'), style: body),
        ],
      ),
    );
  }
}
