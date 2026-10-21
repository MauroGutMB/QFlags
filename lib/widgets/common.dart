import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../game/flag_colors.dart';
import '../l10n/strings.dart';
import '../models/country.dart';
import '../theme/app_theme.dart';

/// Esqueleto padrão das telas: fundo, área segura e margem de 24.
class QScreen extends StatelessWidget {
  const QScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(padding: const EdgeInsets.all(24), child: child),
        ),
      );
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: CircleBorder(side: BorderSide(color: c.border)),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor ?? c.text, size: 22),
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      ),
    );
  }
}

/// Cabeçalho com botão de voltar + título.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          CircleIconButton(
            icon: Icons.chevron_left,
            tooltip: context.tr('back'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: display(26, color: context.colors.text))),
        ],
      );
}

enum BigButtonStyle { primary, outlined }

class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = BigButtonStyle.outlined,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final BigButtonStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final primary = style == BigButtonStyle.primary;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: primary ? c.primary : c.surface,
          foregroundColor: primary ? c.onPrimary : c.text,
          disabledBackgroundColor: primary ? c.primary.withValues(alpha: .45) : c.surface,
          disabledForegroundColor: primary ? c.onPrimary : c.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: primary ? BorderSide.none : BorderSide(color: c.border, width: 2),
          ),
          textStyle: primary
              ? display(20)
              : const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
    this.icon,
    this.fontSize = 15,
  });

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 6),
            ],
            Text(text, style: display(fontSize, color: foreground)),
          ],
        ),
      );
}

/// Bandeira do país. Com [half] mostra só a metade esquerda; com [colors],
/// as cores passam pela matriz (modo Memória).
class FlagImage extends StatelessWidget {
  const FlagImage({
    super.key,
    required this.country,
    required this.size,
    this.half = false,
    this.colors,
  });

  final Country country;
  final double size;
  final bool half;
  final ColorMatrix? colors;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      country.flagAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: half ? null : country.name(context.lang),
      excludeFromSemantics: half,
    );
    final matrix = colors;
    // Inclusive a verdadeira (identidade) passa pelo filtro: as 4 versões do
    // modo Memória são desenhadas exatamente do mesmo jeito.
    final flag = matrix == null
        ? image
        : ColorFiltered(colorFilter: ColorFilter.matrix(matrix.toFilterMatrix()), child: image);
    if (!half) return flag;
    return ClipRect(
      child: Align(alignment: Alignment.centerLeft, widthFactor: .5, child: flag),
    );
  }
}

/// Botões de idioma e tema.
class SettingsControls extends StatelessWidget {
  const SettingsControls({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final langLabel = settings.lang == AppLang.pt ? 'PT · EN' : 'EN · PT';
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Semantics(
          button: true,
          label: context.tr('change_language'),
          excludeSemantics: true,
          child: Material(
            color: c.surface,
            shape: StadiumBorder(side: BorderSide(color: c.border)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: settings.toggleLang,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: Text(
                  langLabel,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: c.text),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        CircleIconButton(
          icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          iconColor: isDark ? c.timeAttack : c.text,
          tooltip: context.tr(isDark ? 'light_mode' : 'dark_mode'),
          onPressed: () => settings.toggleTheme(brightness),
        ),
      ],
    );
  }
}
