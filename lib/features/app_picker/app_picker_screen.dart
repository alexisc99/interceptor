import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import '../../core/platform/interception_channel.dart';
import '../../core/storage/app_config_repository.dart';
import '../../core/storage/stats_repository.dart';
import '../../l10n/app_localizations.dart';

class AppPickerScreen extends StatefulWidget {
  const AppPickerScreen({super.key});

  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  final _repository = AppConfigRepository();
  List<AppInfo>? _apps;
  final Set<String> _selected = {};
  final Map<String, Uint8List?> _icons = {};

  @override
  void initState() {
    super.initState();
    _selected.addAll(_repository.getAll().map((c) => c.packageName));
    _loadApps();
  }

  Future<void> _loadApps() async {
    // Fetched without icons first so the list renders immediately: decoding
    // and PNG-encoding every app's icon natively (installed_apps plugin) is
    // what makes the withIcon:true call slow, so icons are loaded lazily
    // below instead of blocking the initial render.
    final apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: true,
      excludeNonLaunchableApps: true,
      withIcon: false,
    );
    if (mounted) setState(() => _apps = apps);
    _loadIcons(apps);
  }

  void _loadIcons(List<AppInfo> apps) {
    for (final app in apps) {
      InstalledApps.getAppInfo(app.packageName).then((info) {
        if (!mounted) return;
        setState(() => _icons[app.packageName] = info?.icon);
      });
    }
  }

  Future<void> _save() async {
    final existing = _repository.getAll();

    for (final config in existing) {
      if (!_selected.contains(config.packageName)) {
        await _repository.remove(config.packageName);
        await StatsRepository().clearBeforeInstallBaseline(config.packageName);
      }
    }

    for (final packageName in _selected) {
      if (_repository.isTargeted(packageName)) continue;
      final app = _apps?.firstWhere((a) => a.packageName == packageName);
      final addedAt = DateTime.now();
      await _repository.upsert(TargetAppConfig(
        packageName: packageName,
        appName: app?.name ?? packageName,
        addedAt: addedAt,
      ));
      await InterceptionChannel.setGraceMinutes(packageName, 5);
      // Captured now, while it's still fresh: the "week before" baseline
      // used by the advanced stats' "vs before Interceptor" comparison
      // becomes permanently unrecoverable once too much time has passed.
      // Skipped if this app was removed too recently — those 7 days would
      // still be partly under Interceptor's influence, not free use.
      if (StatsRepository().canCaptureBaseline(packageName, addedAt)) {
        final baseline = await InterceptionChannel.getUsageMinutesInRange(
          packageName,
          addedAt.subtract(const Duration(days: 7)),
          addedAt,
        );
        if (baseline != null) {
          await StatsRepository().setBeforeInstallBaselineMinutes(packageName, baseline);
        }
      }
    }

    await InterceptionChannel.setTargetPackages(_selected);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final apps = _apps;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pickerTitle),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(l10n.validateLabel),
          ),
        ],
      ),
      body: apps == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                final selected = _selected.contains(app.packageName);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selected.add(app.packageName);
                      } else {
                        _selected.remove(app.packageName);
                      }
                    });
                  },
                  secondary: _AppIcon(icon: _icons[app.packageName]),
                  title: Text(app.name),
                );
              },
            ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final Uint8List? icon;

  const _AppIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    if (icon == null) return const Icon(Icons.apps);
    return CircleAvatar(backgroundImage: MemoryImage(icon!));
  }
}
