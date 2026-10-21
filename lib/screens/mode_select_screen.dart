import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/game_mode.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'game_screen.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return QScreen(
      child: ListView(
        children: [
          ScreenHeader(title: context.tr('choose_mode')),
          const SizedBox(height: 20),
          for (final mode in GameMode.values) ...[
            Material(
              color: c.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: c.border, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => GameScreen(mode: mode)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: mode.accent(c),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(mode.icon, color: c.onAccent, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr(mode.titleKey), style: display(20, color: c.text)),
                            const SizedBox(height: 4),
                            Text(
                              context.tr(mode.subtitleKey),
                              style: TextStyle(fontSize: 14, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: c.muted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}
