import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_icons.dart';

/// Bouton d'action principal : fond en dégradé orange -> jaune (comme le
/// logo), coins arrondis marqués, texte en gras. À utiliser pour l'action
/// la plus importante d'un écran (ex : "Ajouter le véhicule").
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.loading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || loading;

    final button = Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: disabled ? null : AppColors.primaryGradient,
          color: disabled ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primaryOrange.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: disabled ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                else if (icon != null) ...[
                  Icon(icon, color: disabled ? Colors.grey.shade600 : Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                if (!loading)
                  Text(
                    label,
                    style: TextStyle(
                      color: disabled ? Colors.grey.shade600 : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Bouton secondaire : contour orange, fond transparent/crème, texte orange.
/// À utiliser pour les actions secondaires (ex : "Annuler").
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;

  const AppSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryOrange,
        side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Bouton destructeur (rouge/rust) : pour les actions irréversibles
/// comme "Supprimer".
class AppDestructiveButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool expand;

  const AppDestructiveButton({
    super.key,
    this.label = 'Supprimer',
    this.icon = AppIcons.delete,
    required this.onPressed,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.destructive,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Petit bouton d'icône circulaire, fond rust foncé (comme le moyeu de roue
/// du logo) avec icône blanche. Pensé pour les actions compactes en liste
/// (modifier, supprimer) sans prendre trop de place.
class AppCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color backgroundColor;

  const AppCircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor = AppColors.darkRust,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}

/// FloatingActionButton étendu au style du logo : dégradé orange -> jaune.
/// Remplace le FloatingActionButton.extended standard sur l'écran de liste.
class AppGradientFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const AppGradientFab({
    super.key,
    required this.label,
    this.icon = AppIcons.add,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
