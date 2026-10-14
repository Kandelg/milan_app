import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/data/providers.dart';
import 'package:milan_app/data/safety_repository.dart';

/// Bottom sheet with Block and Report actions for a profile.
class SafetySheet extends ConsumerStatefulWidget {
  const SafetySheet({
    super.key,
    required this.targetId,
    required this.targetName,
  });

  final String targetId;
  final String targetName;

  /// Shows the sheet. Returns `true` when the person was blocked (so the
  /// caller can remove them from the deck).
  static Future<bool?> show(
    BuildContext context, {
    required String targetId,
    required String targetName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) =>
          SafetySheet(targetId: targetId, targetName: targetName),
    );
  }

  @override
  ConsumerState<SafetySheet> createState() => _SafetySheetState();
}

class _SafetySheetState extends ConsumerState<SafetySheet> {
  bool _busy = false;

  bool get _ne =>
      AppStrings.of(context).language == AppLanguage.nepali;

  Future<void> _block() async {
    if (_busy) return;
    final AppStrings strings = AppStrings.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('${strings.block} ${widget.targetName}?'),
        content: Text(
          _ne
              ? '${widget.targetName} तपाईंलाई फेरि देख्नेछैनन् र तपाईं पनि '
                  'उनीहरूलाई देख्नुहुनेछैन।'
              : '${widget.targetName} will no longer appear in your deck '
                  'and yours will not appear in theirs.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.block),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(safetyRepositoryProvider).block(widget.targetId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) showAppSnack(context, 'Block failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _report() async {
    if (_busy) return;
    final ReportReason? reason = await showModalBottomSheet<ReportReason>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) =>
          _ReasonPicker(title: AppStrings.of(context).report),
    );
    if (reason == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(safetyRepositoryProvider).report(
            reportedId: widget.targetId,
            reason: reason.value,
          );
      if (mounted) {
        Navigator.of(context).pop(false);
        showAppSnack(
          context,
          _ne ? 'रिपोर्ट पठाइयो। धन्यवाद!' : 'Report sent. Thank you.',
        );
      }
    } catch (error) {
      if (mounted) showAppSnack(context, 'Report failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: GlassCard(
        borderRadius: 28,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.targetName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 20),
            _ActionTile(
              icon: Icons.block,
              color: Colors.red.shade400,
              label: strings.block,
              subtitle: _ne
                  ? 'त्यो व्यक्ति फेरि देखिने छैन'
                  : 'They disappear from your deck',
              onTap: _busy ? null : _block,
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.flag_outlined,
              color: Colors.orange.shade700,
              label: strings.report,
              subtitle: _ne
                  ? 'समुदाय सुपरकारीलाई जानकारी दिनुहोस्'
                  : 'Let moderators know',
              onTap: _busy ? null : _report,
            ),
            const SizedBox(height: 12),
            if (_busy) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class _ReasonPicker extends StatelessWidget {
  const _ReasonPicker({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: GlassCard(
        borderRadius: 28,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final ReportReason reason in ReportReason.all)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.radio_button_off),
                title: Text(reason.label),
                onTap: () => Navigator.of(context).pop(reason),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
