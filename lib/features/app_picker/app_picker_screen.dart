import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import '../../core/platform/interception_channel.dart';
import '../../core/storage/app_config_repository.dart';

class AppPickerScreen extends StatefulWidget {
  const AppPickerScreen({super.key});

  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  final _repository = AppConfigRepository();
  List<AppInfo>? _apps;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _selected.addAll(_repository.getAll().map((c) => c.packageName));
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: true,
      excludeNonLaunchableApps: true,
      withIcon: true,
    );
    if (mounted) setState(() => _apps = apps);
  }

  Future<void> _save() async {
    final existing = _repository.getAll();

    for (final config in existing) {
      if (!_selected.contains(config.packageName)) {
        await _repository.remove(config.packageName);
      }
    }

    for (final packageName in _selected) {
      if (_repository.isTargeted(packageName)) continue;
      final app = _apps?.firstWhere((a) => a.packageName == packageName);
      await _repository.upsert(TargetAppConfig(
        packageName: packageName,
        appName: app?.name ?? packageName,
      ));
      await InterceptionChannel.setGraceMinutes(packageName, 5);
    }

    await InterceptionChannel.setTargetPackages(_selected);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final apps = _apps;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir des apps'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Valider'),
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
                  secondary: _AppIcon(icon: app.icon),
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
