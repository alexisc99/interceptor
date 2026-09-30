import 'package:flutter/material.dart';

import '../../core/storage/premium_repository.dart';
import '../../l10n/app_localizations.dart';
import 'premium_stats_screen.dart';

/// Shown instead of [PremiumStatsScreen] until the user is premium. Real
/// billing isn't wired up yet, so this offers a plain toggle standing in for
/// "purchase" — swap it for an actual purchase flow once billing exists.
class PremiumGateScreen extends StatefulWidget {
  const PremiumGateScreen({super.key});

  @override
  State<PremiumGateScreen> createState() => _PremiumGateScreenState();
}

class _PremiumGateScreenState extends State<PremiumGateScreen> {
  final _repository = PremiumRepository();
  late bool _isPremium = _repository.isPremium;

  Future<void> _togglePremium(bool value) async {
    await _repository.setPremium(value);
    setState(() => _isPremium = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.premiumLockedTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.workspace_premium, size: 64),
            const SizedBox(height: 20),
            Text(
              l10n.premiumLockedDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            SwitchListTile(
              value: _isPremium,
              onChanged: _togglePremium,
              title: Text(l10n.premiumDebugToggleLabel),
            ),
            const SizedBox(height: 16),
            if (_isPremium)
              FilledButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const PremiumStatsScreen()),
                ),
                child: Text(l10n.viewLabel),
              ),
          ],
        ),
      ),
    );
  }
}
