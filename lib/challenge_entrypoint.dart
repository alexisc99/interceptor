import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/platform/challenge_channel.dart';
import 'core/storage/app_config_repository.dart';
import 'core/storage/stats_repository.dart';
import 'features/challenge/action/action_challenge_screen.dart';
import 'features/challenge/delay/delay_challenge_screen.dart';
import 'features/challenge/math/math_challenge_screen.dart';
import 'features/challenge/mirror/mirror_challenge_screen.dart';
import 'features/challenge/puzzle/puzzle_challenge_screen.dart';
import 'l10n/app_localizations.dart';

/// UI for the challenge overlay. The Dart entrypoint that runs this (used by
/// ChallengeActivity's own Flutter engine/isolate) lives in main.dart.
class ChallengeApp extends StatelessWidget {
  const ChallengeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _ChallengeLoader(),
    );
  }
}

class _ChallengeLoader extends StatefulWidget {
  const _ChallengeLoader();

  @override
  State<_ChallengeLoader> createState() => _ChallengeLoaderState();
}

class _ChallengeLoaderState extends State<_ChallengeLoader> {
  TargetAppConfig? _config;
  ChallengeType? _resolvedType;
  int? _usageMinutesToday;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Hive.initFlutter();
    // reload(), not init(): this engine's process can persist across
    // triggers, and a stale cached box would miss config edits (e.g.
    // challenge type changes) made since the last trigger.
    await AppConfigRepository.reload();
    await StatsRepository.init();

    final targetPackage = await ChallengeChannel.getTargetPackage();
    final usageMinutesToday = await ChallengeChannel.getTodayUsageMinutes();

    final matches = AppConfigRepository().getAll().where((c) => c.packageName == targetPackage);
    final config = matches.isEmpty ? null : matches.first;
    final resolvedConfig = config ?? TargetAppConfig(packageName: targetPackage, appName: targetPackage);

    final eligible = await _eligibleTypes(resolvedConfig.challengeTypes);
    final pool = eligible.isEmpty ? {ChallengeType.math} : eligible;
    final resolvedType = pool.elementAt(Random().nextInt(pool.length));

    await StatsRepository().recordTriggered(targetPackage, resolvedType);
    if (usageMinutesToday != null) {
      await StatsRepository().recordUsageSnapshot(targetPackage, usageMinutesToday);
    }

    // Leaving via Home/Recents instead of the in-app cancel button still
    // counts as a dissuasion — the native side finishes the activity
    // either way, this just makes sure it's recorded.
    ChallengeChannel.setOnUserLeftWithoutSolving(
      () => StatsRepository().recordCancelled(targetPackage, resolvedType),
    );

    if (mounted) {
      setState(() {
        _config = resolvedConfig;
        _resolvedType = resolvedType;
        _usageMinutesToday = usageMinutesToday;
      });
    }
  }

  /// Narrows [selected] down to the types the device currently has whatever
  /// permission they require for — e.g. Mirror is dropped if camera access
  /// was revoked after being selected (selecting it in the first place
  /// already requires granting it, in AppConfigScreen).
  Future<Set<ChallengeType>> _eligibleTypes(Set<ChallengeType> selected) async {
    final needsCameraCheck = selected.any((t) => t.requiresCameraPermission);
    final hasCamera = needsCameraCheck ? await Permission.camera.isGranted : false;
    return selected.where((t) => !t.requiresCameraPermission || hasCamera).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final resolvedType = _resolvedType;
    if (config == null || resolvedType == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    switch (resolvedType) {
      case ChallengeType.math:
        return MathChallengeScreen(
          appConfig: config,
          resolvedType: resolvedType,
          usageMinutesToday: _usageMinutesToday,
        );
      case ChallengeType.puzzle:
        return PuzzleChallengeScreen(
          appConfig: config,
          resolvedType: resolvedType,
          usageMinutesToday: _usageMinutesToday,
        );
      case ChallengeType.action:
        return ActionChallengeScreen(
          appConfig: config,
          resolvedType: resolvedType,
          usageMinutesToday: _usageMinutesToday,
        );
      case ChallengeType.delay:
        return DelayChallengeScreen(
          appConfig: config,
          resolvedType: resolvedType,
          usageMinutesToday: _usageMinutesToday,
        );
      case ChallengeType.mirror:
        return MirrorChallengeScreen(
          appConfig: config,
          resolvedType: resolvedType,
          usageMinutesToday: _usageMinutesToday,
        );
    }
  }
}
